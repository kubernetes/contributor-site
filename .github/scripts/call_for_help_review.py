#!/usr/bin/env python3
"""
Call for Help Review Bot

⚠️ DRAFT / EXPERIMENTAL: This bot is in testing and subject to change.
Feedback and contributions are welcome.

Automatically verifies that a Call for Help request is submitted by an authorized
SIG chair, tech lead, subproject owner, or organization member.

Checks (in order):
1. Primary repository OWNERS file (approvers/reviewers)
2. kubernetes/community sigs.yaml (chairs/tech_leads)
3. kubernetes or kubernetes-sigs org membership

If authorized: auto-adds `call-for-help-approved` label and notifies SIG leads.
If not: posts a comment explaining the verification process.
"""

import os
import sys
import json
import re
import base64
import urllib.request
import urllib.error
import yaml


def github_api_request(url, token=None, method='GET', data=None):
    """Make a GitHub API request and return JSON, or None on 404."""
    headers = {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'k8s-call-for-help-bot',
        'X-GitHub-Api-Version': '2022-11-28'
    }
    if token:
        headers['Authorization'] = f'Bearer {token}'

    req = urllib.request.Request(url, headers=headers, method=method)
    if data:
        req.add_header('Content-Type', 'application/json')

    try:
        with urllib.request.urlopen(req, timeout=15) as response:
            return json.loads(response.read().decode())
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        body = e.read().decode()
        print(f"API error {e.code}: {body}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"Request error: {e}", file=sys.stderr)
        return None


def parse_issue_body(body):
    """Parse GitHub issue body from a form template to extract fields."""
    fields = {}

    # Extract Primary Repository
    repo_match = re.search(
        r'###\s*Primary Repository\s*\n\s*(?:\n)?\s*([^\n]+)',
        body, re.MULTILINE
    )
    if repo_match:
        fields['repo'] = repo_match.group(1).strip()

    # Extract SIG
    sig_match = re.search(
        r'###\s*SIG\s*\n\s*(?:\n)?\s*([^\n]+)',
        body, re.MULTILINE
    )
    if sig_match:
        fields['sig'] = sig_match.group(1).strip()

    # Extract Subproject
    sub_match = re.search(
        r'###\s*Subproject\s*\n\s*(?:\n)?\s*([^\n]+)',
        body, re.MULTILINE
    )
    if sub_match:
        fields['subproject'] = sub_match.group(1).strip()

    # Extract NCO feature request
    nco_match = re.search(
        r'###\s*New Contributor Orientation\s*\n.*?\n\s*-\s*\[x\].*?NCO',
        body, re.DOTALL | re.IGNORECASE
    )
    fields['nco'] = bool(nco_match)

    return fields


def normalize_repo_url(repo):
    """Convert various repo formats to owner/repo."""
    repo = repo.strip()
    # Remove https://github.com/ prefix
    repo = re.sub(r'^https?://github\.com/', '', repo)
    # Remove trailing slashes
    repo = repo.rstrip('/')
    # Should now be owner/repo format
    if re.match(r'^[\w.-]+/[\w.-]+$', repo):
        return repo
    return None


def check_owners_file(repo, username, token):
    """Check if username is in the repo's OWNERS file (approvers or reviewers)."""
    data = github_api_request(
        f"https://api.github.com/repos/{repo}/contents/OWNERS", token
    )
    if not data:
        return False, ""

    try:
        content = base64.b64decode(data.get('content', '')).decode('utf-8')
        # Look for the username in the OWNERS YAML
        # Match patterns like:
        #   approvers:
        #     - lavalamp
        #     - deads2k
        #   reviewers:
        #     - username
        # Also handle inline formats
        patterns = [
            rf'^\s*[-*]\s*{re.escape(username)}\s*$',
            rf'^\s*[-*]\s*@?{re.escape(username)}\s*$',
            rf'github:\s*{re.escape(username)}\b',
        ]
        for pattern in patterns:
            if re.search(pattern, content, re.MULTILINE | re.IGNORECASE):
                return True, f"{repo} OWNERS file approver/reviewer"
    except Exception as e:
        print(f"Error parsing OWNERS: {e}", file=sys.stderr)

    return False, ""


def check_sigs_yaml(sig_name, username, token):
    """Check if username is a chair or tech lead in sigs.yaml."""
    sig_data = load_sigs_yaml()
    
    for sig in sig_data.get('sigs', []):
        name = sig.get('name', '')
        if name == sig_name or f"SIG {name}" == sig_name:
            leadership = sig.get('leadership', {})
            for role in ['chairs', 'tech_leads']:
                for person in leadership.get(role, []):
                    if person.get('github', '').lower() == username.lower():
                        role_name = role[:-1] if role.endswith('s') else role
                        return True, f"{sig_name} {role_name}"
            break
    
    return False, ""


def load_sigs_yaml():
    """Load and cache the kubernetes/community sigs.yaml file."""
    req = urllib.request.Request(
        "https://raw.githubusercontent.com/kubernetes/community/main/sigs.yaml",
        headers={'User-Agent': 'k8s-call-for-help-bot'}
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as response:
            return yaml.safe_load(response.read())
    except Exception as e:
        print(f"Error loading sigs.yaml: {e}", file=sys.stderr)
        return {'sigs': []}


def get_sig_leads(sig_name):
    """Fetch chairs and tech leads from sigs.yaml for a given SIG."""
    sig_data = load_sigs_yaml()
    
    for sig in sig_data.get('sigs', []):
        name = sig.get('name', '')
        if name == sig_name or f"SIG {name}" == sig_name:
            leads = []
            leadership = sig.get('leadership', {})
            for role in ['chairs', 'tech_leads']:
                for person in leadership.get(role, []):
                    gh = person.get('github', '')
                    if gh:
                        leads.append(gh)
            return list(set(leads))  # Remove duplicates
    return []


def get_sig_contribex_leads():
    """Fetch SIG ContribEx chairs and tech leads."""
    return get_sig_leads("Contributor Experience")


def format_mentions(handles):
    """Format a list of GitHub handles as @mentions."""
    if not handles:
        return ""
    mentions = ' '.join(f'@{h}' for h in handles)
    return f"**Notifying:** {mentions}\n\n"


def assign_issue(owner, repo, issue_number, assignees, token):
    """Assign users to an issue."""
    url = f"https://api.github.com/repos/{owner}/{repo}/issues/{issue_number}/assignees"
    data = json.dumps({'assignees': assignees}).encode()
    req = urllib.request.Request(url, data=data, method='POST')
    req.add_header('Authorization', f'Bearer {token}')
    req.add_header('Accept', 'application/vnd.github.v3+json')
    req.add_header('Content-Type', 'application/json')
    req.add_header('User-Agent', 'k8s-call-for-help-bot')
    req.add_header('X-GitHub-Api-Version', '2022-11-28')

    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            print(f"Assigned issue: {response.status}")
    except Exception as e:
        print(f"Failed to assign issue: {e}", file=sys.stderr)


def check_org_membership(username, token):
    """Check if user is a public member of kubernetes or kubernetes-sigs."""
    for org in ['kubernetes', 'kubernetes-sigs']:
        req = urllib.request.Request(
            f"https://api.github.com/orgs/{org}/members/{username}",
            headers={
                'Authorization': f'Bearer {token}',
                'Accept': 'application/vnd.github.v3+json',
                'User-Agent': 'k8s-call-for-help-bot',
                'X-GitHub-Api-Version': '2022-11-28'
            }
        )
        try:
            with urllib.request.urlopen(req, timeout=10) as response:
                if response.status == 204:
                    return True, f"{org} organization member"
        except urllib.error.HTTPError as e:
            if e.code == 404:
                continue
        except Exception as e:
            print(f"Error checking org membership: {e}", file=sys.stderr)

    return False, ""


def add_label(owner, repo, issue_number, label, token):
    """Add a label to an issue."""
    url = f"https://api.github.com/repos/{owner}/{repo}/issues/{issue_number}/labels"
    data = json.dumps([label]).encode()
    req = urllib.request.Request(url, data=data, method='POST')
    req.add_header('Authorization', f'Bearer {token}')
    req.add_header('Accept', 'application/vnd.github.v3+json')
    req.add_header('Content-Type', 'application/json')
    req.add_header('User-Agent', 'k8s-call-for-help-bot')
    req.add_header('X-GitHub-Api-Version', '2022-11-28')

    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            print(f"Added label '{label}': {response.status}")
    except Exception as e:
        print(f"Failed to add label '{label}': {e}", file=sys.stderr)


def remove_label(owner, repo, issue_number, label, token):
    """Remove a label from an issue."""
    url = f"https://api.github.com/repos/{owner}/{repo}/issues/{issue_number}/labels/{label}"
    req = urllib.request.Request(url, method='DELETE')
    req.add_header('Authorization', f'Bearer {token}')
    req.add_header('Accept', 'application/vnd.github.v3+json')
    req.add_header('User-Agent', 'k8s-call-for-help-bot')
    req.add_header('X-GitHub-Api-Version', '2022-11-28')

    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            print(f"Removed label '{label}': {response.status}")
    except Exception as e:
        print(f"Failed to remove label '{label}': {e}", file=sys.stderr)


def post_comment(owner, repo, issue_number, body, token):
    """Post a comment on an issue."""
    url = f"https://api.github.com/repos/{owner}/{repo}/issues/{issue_number}/comments"
    data = json.dumps({'body': body}).encode()
    req = urllib.request.Request(url, data=data, method='POST')
    req.add_header('Authorization', f'Bearer {token}')
    req.add_header('Accept', 'application/vnd.github.v3+json')
    req.add_header('Content-Type', 'application/json')
    req.add_header('User-Agent', 'k8s-call-for-help-bot')
    req.add_header('X-GitHub-Api-Version', '2022-11-28')

    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            print(f"Posted comment: {response.status}")
    except Exception as e:
        print(f"Failed to post comment: {e}", file=sys.stderr)


def main():
    issue_body = os.environ.get('ISSUE_BODY', '')
    issue_creator = os.environ.get('ISSUE_CREATOR', '')
    issue_number = os.environ.get('ISSUE_NUMBER', '')
    repo_owner = os.environ.get('GITHUB_REPO_OWNER', '')
    repo_name = os.environ.get('GITHUB_REPO_NAME', '')
    github_token = os.environ.get('GITHUB_TOKEN', '')

    if not all([issue_body, issue_creator, issue_number, repo_owner, repo_name, github_token]):
        print("Missing required inputs", file=sys.stderr)
        sys.exit(1)

    print(f"Reviewing Call for Help request #{issue_number} by @{issue_creator}")

    # Parse issue body
    fields = parse_issue_body(issue_body)
    sig_name = fields.get('sig', '')
    primary_repo = fields.get('repo', '')
    subproject = fields.get('subproject', '')
    nco_requested = fields.get('nco', False)

    print(f"Detected SIG: {sig_name}")
    print(f"Detected Repo: {primary_repo}")
    print(f"Detected Subproject: {subproject}")
    print(f"NCO Requested: {nco_requested}")

    # Check authorization
    is_authorized = False
    auth_reason = ""

    # Check 1: OWNERS file in the primary repository
    if primary_repo:
        owners_repo = normalize_repo_url(primary_repo)
        if owners_repo:
            is_authorized, auth_reason = check_owners_file(
                owners_repo, issue_creator, github_token
            )
            if is_authorized:
                print(f"✅ Authorized via OWNERS file in {owners_repo}")

    # Check 2: sigs.yaml leadership
    if not is_authorized and sig_name and sig_name != 'Other / Multiple SIGs':
        is_authorized, auth_reason = check_sigs_yaml(
            sig_name, issue_creator, github_token
        )
        if is_authorized:
            print(f"✅ Authorized via sigs.yaml as {sig_name} leadership")

    # Check 3: k8s org membership (fallback)
    if not is_authorized:
        is_authorized, auth_reason = check_org_membership(
            issue_creator, github_token
        )
        if is_authorized:
            print(f"✅ Authorized via org membership")

    # Action
    if is_authorized:
        print(f"Auto-approving: {auth_reason}")
        add_label(repo_owner, repo_name, issue_number, 'call-for-help-approved', github_token)

        # Also add NCO label if requested
        if nco_requested:
            add_label(repo_owner, repo_name, issue_number, 'sig-contribex-nco', github_token)
            print("Added NCO feature label")

        # Notify SIG leads of their own request
        sig_leads = get_sig_leads(sig_name)
        lead_mentions = format_mentions(sig_leads)
        
        # Also assign the issue to the SIG leads so they get strong notifications
        if sig_leads:
            assign_issue(repo_owner, repo_name, issue_number, sig_leads[:10], github_token)  # Max 10 assignees

        nco_text = ""
        if nco_requested:
            nco_text = " This project is also featured in the upcoming New Contributor Orientation."

        comment = f"""{lead_mentions}✅ **Automatically Approved**

@{issue_creator} is verified as **{auth_reason}**. This request is now approved and will appear on the [Community Resilience Dashboard](https://kubernetes.dev/community/resilience/) and the [Help Wanted Dashboard](https://kubernetes.dev/community/help-wanted/).{nco_text}

Thank you for helping grow the Kubernetes community! 🌱"""
        post_comment(repo_owner, repo_name, issue_number, comment, github_token)

    else:
        print(f"❌ Not automatically authorized")
        # Notify SIG ContribEx leads for manual review
        contribex_leads = get_sig_contribex_leads()
        lead_mentions = format_mentions(contribex_leads)
        
        # Also assign to SIG ContribEx leads for triage
        if contribex_leads:
            assign_issue(repo_owner, repo_name, issue_number, contribex_leads[:10], github_token)

        comment = f"""{lead_mentions}👋 Hi @{issue_creator}, thanks for your Call for Help request!

This request requires verification before it appears on the dashboard. The system was unable to automatically confirm your authorization.

**What happens next:**
1. A SIG Contributor Experience moderator will review this manually
2. Or, a SIG chair/tech lead can approve by commenting `/call-for-help-approve`
3. Approval typically takes 1-2 business days

**To speed up approval:**
- Ensure you are listed in the [OWNERS file](https://github.com/{primary_repo}/blob/main/OWNERS) or [sigs.yaml](https://github.com/kubernetes/community/blob/main/sigs.yaml) for this project
- Ask a SIG chair to comment on this issue

Thanks for helping grow the Kubernetes community! 🌱"""
        post_comment(repo_owner, repo_name, issue_number, comment, github_token)


if __name__ == '__main__':
    main()
