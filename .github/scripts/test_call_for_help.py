#!/usr/bin/env python3
"""
Test script for the Call for Help Review Bot

⚠️ DRAFT / EXPERIMENTAL: This test suite is for experimentation and validation.

Simulates the GitHub workflow to verify:
1. Issue body parsing
2. SIG lead extraction from sigs.yaml
3. @mention formatting
4. Notification assignment logic
"""

import sys
import os
import yaml
import urllib.request

# Add parent directory to path to import the script
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Import functions from the main script
from call_for_help_review import (
    parse_issue_body,
    load_sigs_yaml,
    get_sig_leads,
    get_sig_contribex_leads,
    format_mentions,
    normalize_repo_url,
)


def test_parse_issue_body():
    """Test parsing a real issue body from the template."""
    print("=" * 60)
    print("TEST 1: Parse Issue Body")
    print("=" * 60)
    
    body = """### SIG

SIG Testing

### Subproject

kind

### What kind of help is needed?

- [x] New contributors / mentorship
- [ ] Code reviewers
- [x] Maintainers / approvers

### New Contributor Orientation

- [x] We want to be featured in the upcoming NCO

### Skills / Languages

- Go
- Shell

### Description

kind is a tool for running local Kubernetes clusters.

### Meeting Time

Tuesdays 9:00 AM PT

### Slack Channel

#sig-testing

### Primary Repository

https://github.com/kubernetes-sigs/kind

### Onboarding Documentation

https://github.com/kubernetes-sigs/kind/blob/main/CONTRIBUTING.md"""

    fields = parse_issue_body(body)
    
    assert fields['sig'] == 'SIG Testing', f"Expected 'SIG Testing', got '{fields['sig']}'"
    assert fields['subproject'] == 'kind', f"Expected 'kind', got '{fields['subproject']}'"
    assert fields['repo'] == 'https://github.com/kubernetes-sigs/kind', f"Expected repo URL, got '{fields['repo']}'"
    assert fields['nco'] == True, f"Expected NCO=True, got {fields['nco']}"
    
    print(f"✅ SIG: {fields['sig']}")
    print(f"✅ Subproject: {fields['subproject']}")
    print(f"✅ Repo: {fields['repo']}")
    print(f"✅ NCO: {fields['nco']}")
    print()


def test_load_sigs_yaml():
    """Test loading the real sigs.yaml from kubernetes/community."""
    print("=" * 60)
    print("TEST 2: Load sigs.yaml")
    print("=" * 60)
    
    data = load_sigs_yaml()
    
    assert 'sigs' in data, "sigs.yaml missing 'sigs' key"
    assert len(data['sigs']) > 0, "sigs.yaml contains no SIGs"
    
    print(f"✅ Loaded {len(data['sigs'])} SIGs from kubernetes/community")
    print()


def test_get_sig_leads():
    """Test extracting SIG leads from sigs.yaml."""
    print("=" * 60)
    print("TEST 3: Get SIG Leads")
    print("=" * 60)
    
    # Test SIG Testing
    testing_leads = get_sig_leads('Testing')
    print(f"SIG Testing leads: {testing_leads}")
    assert len(testing_leads) > 0, "SIG Testing should have leads"
    print(f"✅ Found {len(testing_leads)} leads for SIG Testing")
    
    # Test SIG Contributor Experience
    contribex_leads = get_sig_leads('Contributor Experience')
    print(f"SIG ContribEx leads: {contribex_leads}")
    assert len(contribex_leads) > 0, "SIG ContribEx should have leads"
    print(f"✅ Found {len(contribex_leads)} leads for SIG ContribEx")
    
    # Test unknown SIG
    unknown_leads = get_sig_leads('NonExistent')
    assert len(unknown_leads) == 0, "Unknown SIG should have no leads"
    print(f"✅ Unknown SIG returns empty list")
    print()


def test_get_sig_contribex_leads():
    """Test the convenience function for SIG ContribEx."""
    print("=" * 60)
    print("TEST 4: Get SIG ContribEx Leads")
    print("=" * 60)
    
    leads = get_sig_contribex_leads()
    print(f"SIG ContribEx leads: {leads}")
    assert len(leads) > 0, "SIG ContribEx must have leads"
    print(f"✅ Found {len(leads)} leads")
    print()


def test_format_mentions():
    """Test formatting @mentions."""
    print("=" * 60)
    print("TEST 5: Format Mentions")
    print("=" * 60)
    
    # Test with leads
    leads = ['mrbobbytables', 'nikhita', 'jberkus']
    mentions = format_mentions(leads)
    print(f"Formatted: {mentions}")
    assert '@mrbobbytables' in mentions
    assert '@nikhita' in mentions
    assert '@jberkus' in mentions
    print("✅ Mentions formatted correctly")
    
    # Test empty list
    empty = format_mentions([])
    assert empty == "", f"Expected empty string, got '{empty}'"
    print("✅ Empty list returns empty string")
    print()


def test_normalize_repo_url():
    """Test URL normalization."""
    print("=" * 60)
    print("TEST 6: Normalize Repo URL")
    print("=" * 60)
    
    test_cases = [
        ('https://github.com/kubernetes-sigs/kind', 'kubernetes-sigs/kind'),
        ('https://github.com/kubernetes/kubernetes/', 'kubernetes/kubernetes'),
        ('kubernetes-sigs/kind', 'kubernetes-sigs/kind'),
        ('not-a-url', None),
    ]
    
    for input_url, expected in test_cases:
        result = normalize_repo_url(input_url)
        assert result == expected, f"normalize_repo_url({input_url}) = {result}, expected {expected}"
        print(f"✅ {input_url} -> {result}")
    print()


def test_workflow_simulation():
    """Simulate the complete workflow for a SIG Testing request."""
    print("=" * 60)
    print("TEST 7: Complete Workflow Simulation")
    print("=" * 60)
    
    sig_name = 'Testing'
    subproject = 'kind'
    
    # Step 1: Parse issue
    print("Step 1: Issue parsed")
    print(f"  SIG: {sig_name}")
    print(f"  Subproject: {subproject}")
    
    # Step 2: Get leads
    sig_leads = get_sig_leads(sig_name)
    print(f"Step 2: SIG {sig_name} leads: {sig_leads}")
    
    # Step 3: Format approval comment
    mentions = format_mentions(sig_leads)
    comment = f"""{mentions}✅ **Automatically Approved**

@user is verified as SIG Testing chair. This request is now approved."""
    
    print("Step 3: Approval comment preview:")
    print("-" * 40)
    print(comment)
    print("-" * 40)
    
    # Step 4: Verify notifications
    assert len(sig_leads) > 0, "Should have leads to notify"
    assert '@' in mentions, "Should contain @mentions"
    print("✅ Workflow simulation complete")
    print()


def test_pending_workflow_simulation():
    """Simulate workflow for a pending/unauthorized request."""
    print("=" * 60)
    print("TEST 8: Pending Request Workflow")
    print("=" * 60)
    
    sig_name = 'Unknown SIG'
    
    # Get ContribEx leads for triage
    contribex_leads = get_sig_contribex_leads()
    print(f"SIG ContribEx leads for triage: {contribex_leads}")
    
    mentions = format_mentions(contribex_leads)
    comment = f"""{mentions}👋 Hi @user, thanks for your request!

This request requires manual review."""
    
    print("Triage comment preview:")
    print("-" * 40)
    print(comment)
    print("-" * 40)
    
    assert len(contribex_leads) > 0, "Should have ContribEx leads"
    print("✅ Pending workflow simulation complete")
    print()


def main():
    print("\n" + "=" * 60)
    print("CALL FOR HELP REVIEW BOT - TEST SUITE")
    print("=" * 60 + "\n")
    
    tests = [
        test_parse_issue_body,
        test_load_sigs_yaml,
        test_get_sig_leads,
        test_get_sig_contribex_leads,
        test_format_mentions,
        test_normalize_repo_url,
        test_workflow_simulation,
        test_pending_workflow_simulation,
    ]
    
    passed = 0
    failed = 0
    
    for test in tests:
        try:
            test()
            passed += 1
        except Exception as e:
            failed += 1
            print(f"❌ {test.__name__} FAILED: {e}")
            print()
    
    print("=" * 60)
    print(f"RESULTS: {passed} passed, {failed} failed out of {len(tests)} tests")
    print("=" * 60)
    
    return 0 if failed == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
