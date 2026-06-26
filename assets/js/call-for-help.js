(function() {
  'use strict';

  var SAMPLE_PROJECTS = [
    { repo: 'kubernetes-sigs/kind', sigs: ['SIG Testing'], lang: ['Go', 'Shell'], skills: ['testing', 'containers'], lf: 2, gfi: 12, onboarding_url: 'https://github.com/kubernetes-sigs/kind/blob/main/CONTRIBUTING.md', gfi_url: 'https://github.com/kubernetes-sigs/kind/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22' },
    { repo: 'kubernetes-sigs/gateway-api', sigs: ['SIG Network'], lang: ['Go', 'YAML'], skills: ['networking', 'api-design'], lf: 3, gfi: 8, onboarding_url: 'https://github.com/kubernetes-sigs/gateway-api/blob/main/CONTRIBUTING.md', gfi_url: 'https://github.com/kubernetes-sigs/gateway-api/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22' },
    { repo: 'kubernetes-sigs/krew-index', sigs: ['SIG CLI'], lang: ['YAML', 'Shell'], skills: ['documentation', 'packaging'], lf: 1, gfi: 15, onboarding_url: 'https://github.com/kubernetes-sigs/krew-index/blob/main/CONTRIBUTING.md', gfi_url: 'https://github.com/kubernetes-sigs/krew-index/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22' },
    { repo: 'kubernetes-sigs/security-profiles-operator', sigs: ['SIG Node'], lang: ['Go'], skills: ['security'], lf: 1, gfi: 6, onboarding_url: 'https://github.com/kubernetes-sigs/security-profiles-operator/blob/main/CONTRIBUTING.md', gfi_url: 'https://github.com/kubernetes-sigs/security-profiles-operator/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22' },
    { repo: 'kubernetes-sigs/metrics-server', sigs: ['SIG Instrumentation'], lang: ['Go'], skills: ['metrics'], lf: 2, gfi: 3, onboarding_url: 'https://github.com/kubernetes-sigs/metrics-server/blob/main/CONTRIBUTING.md', gfi_url: 'https://github.com/kubernetes-sigs/metrics-server/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22' },
    { repo: 'kubernetes-sigs/external-dns', sigs: ['SIG Network'], lang: ['Go'], skills: ['dns', 'cloud'], lf: 2, gfi: 10, onboarding_url: 'https://github.com/kubernetes-sigs/external-dns/blob/main/CONTRIBUTING.md', gfi_url: 'https://github.com/kubernetes-sigs/external-dns/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22' },
    { repo: 'kubernetes-sigs/cluster-api', sigs: ['SIG Cluster Lifecycle'], lang: ['Go', 'Python'], skills: ['infrastructure'], lf: 5, gfi: 20, onboarding_url: 'https://github.com/kubernetes-sigs/cluster-api/blob/main/CONTRIBUTING.md', gfi_url: 'https://github.com/kubernetes-sigs/cluster-api/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22' },
    { repo: 'kubernetes-sigs/kubectl-validate', sigs: ['SIG CLI'], lang: ['Go'], skills: ['cli', 'validation'], lf: 3, gfi: 5, onboarding_url: 'https://github.com/kubernetes-sigs/kubectl-validate/blob/main/CONTRIBUTING.md', gfi_url: 'https://github.com/kubernetes-sigs/kubectl-validate/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22' },
    { repo: 'kubernetes-sigs/descheduler', sigs: ['SIG Scheduling'], lang: ['Go'], skills: ['scheduling'], lf: 3, gfi: 7, onboarding_url: 'https://github.com/kubernetes-sigs/descheduler/blob/main/CONTRIBUTING.md', gfi_url: 'https://github.com/kubernetes-sigs/descheduler/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22' },
    { repo: 'kubernetes-sigs/node-feature-discovery', sigs: ['SIG Node'], lang: ['Go', 'Shell'], skills: ['hardware', 'discovery'], lf: 4, gfi: 4, onboarding_url: 'https://github.com/kubernetes-sigs/node-feature-discovery/blob/main/CONTRIBUTING.md', gfi_url: 'https://github.com/kubernetes-sigs/node-feature-discovery/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22' },
  ];

  function escapeHtml(t) {
    var d = document.createElement('div'); d.textContent = t; return d.innerHTML;
  }

  function hasRealData(data) {
    if (!data || data.length === 0) return false;
    for (var i = 0; i < data.length; i++) {
      if (data[i].lottery_factor > 0 && data[i].total_points > 0) return true;
    }
    return false;
  }

  function buildProjects() {
    var data = window.lotteryFactorData;
    var projects = [];

    if (hasRealData(data)) {
      for (var i = 0; i < data.length; i++) {
        var r = data[i];
        if (r.lottery_factor > 0) {
          var ts = r.tech_stack || {};
          projects.push({
            repo: r.repo,
            repoName: r.repo.split('/')[1],
            sig: (r.sigs || [])[0] || '',
            lang: ts.languages || [],
            skills: ts.skills_needed || [],
            lf: r.lottery_factor,
            gfi: ts.good_first_issue_count || 0,
            onboarding_url: r.onboarding_url || '',
            gfi_url: r.good_first_issues_url || '',
          });
        }
      }
    }

    if (projects.length === 0) {
      projects = SAMPLE_PROJECTS.map(function(s) {
        return {
          repo: s.repo,
          repoName: s.repo.split('/')[1],
          sig: (s.sigs || [])[0] || '',
          lang: s.lang || [],
          skills: s.skills || [],
          lf: s.lf,
          gfi: s.gfi,
          onboarding_url: s.onboarding_url || '',
          gfi_url: s.gfi_url || '',
        };
      });
    }

    projects.sort(function(a, b) { return a.lf - b.lf; });
    return projects;
  }

  function renderCard(p, isNCO) {
    var ncoTag = isNCO ? '<span class="nco-tag">NCO</span>' : '';
    var lfTag = p.lf > 0 ? '<span class="risk-tag">LF ' + p.lf + '</span>' : '';
    var langBadges = p.lang.map(function(l) { return '<span class="tag">' + escapeHtml(l) + '</span>'; }).join('');
    var skillBadges = p.skills.map(function(s) { return '<span class="tag-outline">' + escapeHtml(s) + '</span>'; }).join('');
    var gfiLink = p.gfi_url ? '<a href="' + escapeHtml(p.gfi_url) + '" class="btn-sm">Good First Issues' + (p.gfi > 0 ? ' (' + p.gfi + ')' : '') + '</a>' : '';
    var onboardingLink = p.onboarding_url ? '<a href="' + escapeHtml(p.onboarding_url) + '" class="btn-sm">Onboarding</a>' : '';

    return '<div class="call-for-help-card' + (isNCO ? ' nco-featured' : '') + '">' +
      '<div class="card-row top-row">' +
        '<h4 class="project-name"><a href="https://github.com/' + escapeHtml(p.repo) + '" class="project-link">' + escapeHtml(p.repoName) + '</a>' + ncoTag + '</h4>' +
        '<span class="request-type">' + p.sig + '  ' + lfTag + '</span>' +
      '</div>' +
      '<div class="card-row">' + langBadges + skillBadges + '</div>' +
      '<div class="card-row actions">' + gfiLink + onboardingLink + '</div>' +
    '</div>';
  }

  function init(containerId) {
    var container = document.getElementById(containerId);
    if (!container) return;

    var projects = buildProjects();
    if (projects.length === 0) {
      container.innerHTML = '';
      return;
    }

    var ncoThreshold = Math.min(3, Math.ceil(projects.length / 3));
    var ncoProjects = [];
    var otherProjects = [];

    for (var i = 0; i < projects.length; i++) {
      if (i < ncoThreshold && projects[i].lf <= 2) {
        ncoProjects.push(projects[i]);
      } else {
        otherProjects.push(projects[i]);
      }
    }

    var html = '';

    if (window.showNCOOnly && ncoProjects.length > 0) {
      html += '<h3 class="section-title">Featured in New Contributor Orientation</h3>';
      html += '<p class="section-desc">These projects are ready for new contributors.</p>';
      html += '<div class="projects-grid">';
      for (var j = 0; j < ncoProjects.length; j++) html += renderCard(ncoProjects[j], true);
      html += '</div>';
    }

    if (!window.showNCOOnly) {
      if (ncoProjects.length > 0) {
        html += '<p class="section-desc">Featured in New Contributor Orientation</p>';
        html += '<div class="projects-grid">';
        for (var j = 0; j < ncoProjects.length; j++) html += renderCard(ncoProjects[j], true);
        html += '</div>';
      }
      if (otherProjects.length > 0) {
        html += '<p class="section-desc">Projects needing contributors</p>';
        html += '<div class="projects-grid">';
        for (var j = 0; j < otherProjects.length; j++) html += renderCard(otherProjects[j], false);
        html += '</div>';
      }
    }

    if (html === '') {
      container.innerHTML = '';
      return;
    }

    container.innerHTML = html;
  }

  window.initCallForHelpDashboard = init;
})();
