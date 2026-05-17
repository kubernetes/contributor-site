// Call for Help integration for Community Resilience Dashboard
// Fetches issues labeled 'call-for-help' from GitHub API

(function() {
  'use strict';

  const GITHUB_API = 'https://api.github.com';
  const REPO_OWNER = 'kubernetes';
  const REPO_NAME = 'contributor-site';
  const REQUIRED_LABELS = ['call-for-help', 'call-for-help-approved'];
  const NCO_LABELS = ['sig-contribex-nco'];

  const RequestType = {
    REVIEWERS: 'Reviewers',
    MAINTAINERS: 'Maintainers',
    SECURITY: 'Security',
    MENTORSHIP: 'Mentorship',
    OTHER: 'Other'
  };

  async function fetchCallForHelpIssues() {
    try {
      const url = `${GITHUB_API}/repos/${REPO_OWNER}/${REPO_NAME}/issues?labels=call-for-help&state=open&per_page=50`;
      const response = await fetch(url);

      if (!response.ok) {
        console.error('Failed to fetch Call for Help issues:', response.status);
        return [];
      }

      const issues = await response.json();
      return issues.filter(issue => !issue.pull_request);
    } catch (error) {
      console.error('Error fetching Call for Help issues:', error);
      return [];
    }
  }

  function parseRequestType(body) {
    const types = [];
    const lowerBody = body.toLowerCase();

    if (lowerBody.includes('reviewer')) types.push(RequestType.REVIEWERS);
    if (lowerBody.includes('maintainer')) types.push(RequestType.MAINTAINERS);
    if (lowerBody.includes('security')) types.push(RequestType.SECURITY);
    if (lowerBody.includes('mentorship') || lowerBody.includes('mentor')) types.push(RequestType.MENTORSHIP);
    if (lowerBody.includes('other')) types.push(RequestType.OTHER);

    return types.length > 0 ? types : [RequestType.OTHER];
  }

  function extractProjectInfo(issue) {
    const title = issue.title;
    const body = issue.body || '';

    const projectMatch = title.match(/\[Call for Help\]\s*([^:]+):/);
    const project = projectMatch ? projectMatch[1].trim() : title;

    const labels = issue.labels.map(l => l.name);
    const hasNCO = NCO_LABELS.some(l => labels.includes(l));

    return {
      number: issue.number,
      title: issue.title,
      project: project,
      url: issue.html_url,
      requestType: parseRequestType(body),
      hasNCO: hasNCO,
      createdAt: new Date(issue.created_at),
      labels: labels,
      state: issue.state
    };
  }

  function createProjectCard(issue) {
    const daysSinceCreated = Math.floor((Date.now() - issue.createdAt.getTime()) / (1000 * 60 * 60 * 24));
    const isStale = daysSinceCreated > 90;

    const card = document.createElement('div');
    card.className = `call-for-help-card${isStale ? ' stale' : ''}${issue.hasNCO ? ' nco-featured' : ''}`;

    card.innerHTML = `
      <div class="card-header">
        <h4 class="project-name">
          <a href="${issue.url}" target="_blank" rel="noopener">${issue.project}</a>
          ${issue.hasNCO ? '<span class="nco-badge">NCO</span>' : ''}
        </h4>
        <span class="request-type">${issue.requestType.join(', ')}</span>
      </div>
      <div class="card-body">
        <p class="issue-title">${issue.title}</p>
        <div class="card-meta">
          <span class="issue-number">#${issue.number}</span>
          <span class="created-date">${daysSinceCreated} days ago</span>
          ${isStale ? '<span class="stale-badge">Stale</span>' : ''}
        </div>
      </div>
      <div class="card-footer">
        <a href="${issue.url}" class="btn btn-sm btn-outline-primary" target="_blank" rel="noopener">
          View Issue
        </a>
        <a href="${issue.url.replace('issues/', 'issues?q=is%3Aissue+is%3Aopen+label%3Agood-first-issue')}" class="btn btn-sm btn-outline-secondary" target="_blank" rel="noopener">
          Good First Issues
        </a>
      </div>
    `;

    return card;
  }

  async function initCallForHelpDashboard(containerId) {
    const container = document.getElementById(containerId);
    if (!container) return;

    container.innerHTML = '<div class="loading">Loading Call for Help requests...</div>';

    const issues = await fetchCallForHelpIssues();
    const parsed = issues.map(extractProjectInfo);

    if (parsed.length === 0) {
      container.innerHTML = `
        <div class="no-requests">
          <p>No active Call for Help requests at this time.</p>
          <p class="help-text">
            SIG Chairs and Tech Leads can
            <a href="https://github.com/${REPO_OWNER}/${REPO_NAME}/issues/new?template=call-for-help.yaml" target="_blank" rel="noopener">
              create a request
            </a>
            if their project needs assistance.
          </p>
        </div>
      `;
      return;
    }

    const ncoProjects = parsed.filter(p => p.hasNCO);
    const otherProjects = parsed.filter(p => !p.hasNCO);

    let html = '<div class="call-for-help-section">';

    if (ncoProjects.length > 0) {
      html += `
        <div class="nco-projects">
          <h3>New Contributor Orientation Featured Projects</h3>
          <p class="section-desc">These projects are looking for new contributors!</p>
          <div class="projects-grid">
            ${ncoProjects.map(p => createProjectCard(p).outerHTML).join('')}
          </div>
        </div>
      `;
    }

    if (otherProjects.length > 0) {
      html += `
        <div class="other-projects">
          <h3>Projects Needing Assistance</h3>
          <div class="projects-grid">
            ${otherProjects.map(p => createProjectCard(p).outerHTML).join('')}
          </div>
        </div>
      `;
    }

    html += '</div>';
    container.innerHTML = html;
  }

  window.initCallForHelpDashboard = initCallForHelpDashboard;
  window.fetchCallForHelpIssues = fetchCallForHelpIssues;

})();