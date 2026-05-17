// Call for Help integration for Community Resilience Dashboard
// Fetches issues labeled 'call-for-help-approved' from GitHub API

(function() {
  'use strict';

  const GITHUB_API = 'https://api.github.com';
  const REPO_OWNER = 'kubernetes';
  const REPO_NAME = 'contributor-site';
  const APPROVED_LABEL = 'call-for-help-approved';
  const NCO_LABELS = ['sig-contribex-nco'];

  const RequestType = {
    REVIEWERS: 'Reviewers',
    MAINTAINERS: 'Maintainers',
    SECURITY: 'Security',
    MENTORSHIP: 'Mentorship',
    OTHER: 'Other'
  };

  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  async function fetchCallForHelpIssues() {
    try {
      // Fetch only approved issues
      const url = `${GITHUB_API}/repos/${REPO_OWNER}/${REPO_NAME}/issues?labels=${APPROVED_LABEL}&state=open&per_page=50`;
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

    // Header
    const header = document.createElement('div');
    header.className = 'card-header';

    const titleWrapper = document.createElement('h4');
    titleWrapper.className = 'project-name';

    const link = document.createElement('a');
    link.href = issue.url;
    link.target = '_blank';
    link.rel = 'noopener';
    link.textContent = issue.project;

    titleWrapper.appendChild(link);

    if (issue.hasNCO) {
      const ncoBadge = document.createElement('span');
      ncoBadge.className = 'nco-badge';
      ncoBadge.textContent = 'NCO';
      titleWrapper.appendChild(ncoBadge);
    }

    const typeSpan = document.createElement('span');
    typeSpan.className = 'request-type';
    typeSpan.textContent = issue.requestType.join(', ');

    header.appendChild(titleWrapper);
    header.appendChild(typeSpan);

    // Body
    const body = document.createElement('div');
    body.className = 'card-body';

    const titlePara = document.createElement('p');
    titlePara.className = 'issue-title';
    titlePara.textContent = issue.title;

    const metaDiv = document.createElement('div');
    metaDiv.className = 'card-meta';

    const numberSpan = document.createElement('span');
    numberSpan.className = 'issue-number';
    numberSpan.textContent = '#' + issue.number;

    const dateSpan = document.createElement('span');
    dateSpan.className = 'created-date';
    dateSpan.textContent = daysSinceCreated + ' days ago';

    metaDiv.appendChild(numberSpan);
    metaDiv.appendChild(dateSpan);

    if (isStale) {
      const staleBadge = document.createElement('span');
      staleBadge.className = 'stale-badge';
      staleBadge.textContent = 'Stale';
      metaDiv.appendChild(staleBadge);
    }

    body.appendChild(titlePara);
    body.appendChild(metaDiv);

    // Footer
    const footer = document.createElement('div');
    footer.className = 'card-footer';

    // Fix malformed Good First Issues URL
    const baseUrl = issue.url.replace(/\/issues\/\d+$/, '');

    const viewBtn = document.createElement('a');
    viewBtn.href = issue.url;
    viewBtn.className = 'btn btn-sm btn-outline-primary';
    viewBtn.target = '_blank';
    viewBtn.rel = 'noopener';
    viewBtn.textContent = 'View Issue';

    const gfiBtn = document.createElement('a');
    gfiBtn.href = baseUrl + '?q=is%3Aissue+is%3Aopen+label%3Agood-first-issue';
    gfiBtn.className = 'btn btn-sm btn-outline-secondary';
    gfiBtn.target = '_blank';
    gfiBtn.rel = 'noopener';
    gfiBtn.textContent = 'Good First Issues';

    footer.appendChild(viewBtn);
    footer.appendChild(gfiBtn);

    // Append all sections
    card.appendChild(header);
    card.appendChild(body);
    card.appendChild(footer);

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