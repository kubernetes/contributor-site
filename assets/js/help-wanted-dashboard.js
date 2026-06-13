(function() {
  'use strict';

  var PAGE_SIZE = 12;

  var SAMPLE_PROJECTS = [
    { repo: 'kubernetes-sigs/kind', sig: 'SIG Testing', lang: ['Go', 'Shell'], skills: ['testing', 'containers'], lf: 2, gfi: 12 },
    { repo: 'kubernetes-sigs/gateway-api', sig: 'SIG Network', lang: ['Go', 'YAML'], skills: ['networking', 'api-design'], lf: 3, gfi: 8 },
    { repo: 'kubernetes-sigs/krew-index', sig: 'SIG CLI', lang: ['YAML', 'Shell'], skills: ['documentation', 'packaging'], lf: 1, gfi: 15 },
    { repo: 'kubernetes-sigs/security-profiles-operator', sig: 'SIG Node', lang: ['Go'], skills: ['security'], lf: 1, gfi: 6 },
    { repo: 'kubernetes-sigs/external-dns', sig: 'SIG Network', lang: ['Go'], skills: ['dns', 'cloud'], lf: 2, gfi: 10 },
    { repo: 'kubernetes-sigs/kubectl-validate', sig: 'SIG CLI', lang: ['Go'], skills: ['cli', 'validation'], lf: 3, gfi: 5 },
    { repo: 'kubernetes-sigs/metrics-server', sig: 'SIG Instrumentation', lang: ['Go'], skills: ['metrics', 'performance'], lf: 2, gfi: 3 },
    { repo: 'kubernetes-sigs/descheduler', sig: 'SIG Scheduling', lang: ['Go'], skills: ['scheduling', 'optimization'], lf: 3, gfi: 7 },
    { repo: 'kubernetes-sigs/cluster-api', sig: 'SIG Cluster Lifecycle', lang: ['Go', 'Python'], skills: ['infrastructure', 'automation'], lf: 5, gfi: 20 },
    { repo: 'kubernetes-sigs/node-feature-discovery', sig: 'SIG Node', lang: ['Go', 'Shell'], skills: ['hardware', 'discovery'], lf: 4, gfi: 4 },
    { repo: 'kubernetes-sigs/ingress-nginx', sig: 'SIG Network', lang: ['Go', 'Lua'], skills: ['networking', 'reverse-proxy'], lf: 2, gfi: 9 },
    { repo: 'kubernetes-sigs/kueue', sig: 'SIG Scheduling', lang: ['Go'], skills: ['batch', 'scheduling'], lf: 3, gfi: 11 },
    { repo: 'kubernetes-sigs/kustomize', sig: 'SIG CLI', lang: ['Go'], skills: ['configuration', 'templating'], lf: 4, gfi: 6 },
    { repo: 'kubernetes-sigs/kwok', sig: 'SIG Scheduling', lang: ['Go'], skills: ['testing', 'simulation'], lf: 2, gfi: 8 },
  ];

  var allProjects = [];
  var filteredProjects = [];
  var currentPage = 1;

  function escapeHtml(t) {
    var d = document.createElement('div'); d.textContent = t; return d.innerHTML;
  }

  function hasRealData(data) {
    if (!data || data.length === 0) return false;
    for (var i = 0; i < data.length; i++) {
      if (data[i].total_points > 100) return true;
    }
    return false;
  }

  function findSigInfo(sigName) {
    var yaml = window.sigsYamlData;
    if (!yaml || !yaml.sigs) return null;
    for (var i = 0; i < yaml.sigs.length; i++) {
      var s = yaml.sigs[i];
      if (s.name === sigName || 'SIG ' + s.name === sigName) {
        // Get the first meeting
        var meeting = null;
        if (s.meetings && s.meetings.length > 0) {
          meeting = s.meetings[0];
        }
        return {
          name: s.name,
          dir: s.dir || '',
          meeting: meeting,
          slack: s.contact ? s.contact.slack : null,
          description: s.mission_statement || ''
        };
      }
    }
    return null;
  }

  function sigPageUrl(sigInfo) {
    if (!sigInfo || !sigInfo.dir) return '';
    var name = sigInfo.dir.replace(/^sig-/, '');
    return '/community/community-groups/sigs/' + name + '/';
  }

  function buildProjects() {
    var data = window.lotteryFactorData;
    var result = [];

    if (hasRealData(data)) {
      for (var i = 0; i < data.length; i++) {
        var r = data[i];
        var ts = r.tech_stack || {};
        var sigName = (r.sigs || [])[0] || '';
        var sigInfo = findSigInfo(sigName);
        result.push({
          repo: r.repo,
          repoName: r.repo.split('/')[1],
          sig: sigName,
          sigInfo: sigInfo,
          sigUrl: sigPageUrl(sigInfo),
          lang: ts.languages || [],
          skills: ts.skills_needed || [],
          lf: r.lottery_factor || 0,
          gfi: ts.good_first_issue_count || 0,
          gfi_url: r.good_first_issues_url || '',
          onboarding_url: r.onboarding_url || '',
        });
      }
    }

    if (result.length === 0) {
      result = SAMPLE_PROJECTS.map(function(s) {
        var sigInfo = findSigInfo(s.sig);
        return {
          repo: s.repo,
          repoName: s.repo.split('/')[1],
          sig: s.sig,
          sigInfo: sigInfo,
          sigUrl: sigPageUrl(sigInfo),
          lang: s.lang || [],
          skills: s.skills || [],
          lf: s.lf,
          gfi: s.gfi,
          gfi_url: 'https://github.com/' + s.repo + '/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22',
          onboarding_url: 'https://github.com/' + s.repo + '/blob/main/CONTRIBUTING.md',
        };
      });
    }

    result.sort(function(a, b) { return a.lf - b.lf; });
    return result;
  }

  function init() {
    var grid = document.getElementById('projectsGrid');
    if (!grid) return;
    allProjects = buildProjects();
    applyFilters();
    bindEvents();
  }

  function applyFilters() {
    var search = (document.getElementById('searchFilter')?.value || '').toLowerCase().trim();
    var language = document.getElementById('languageFilter')?.value || 'all';
    var skill = document.getElementById('skillFilter')?.value || 'all';
    var sig = document.getElementById('sigFilter')?.value || 'all';
    var day = document.getElementById('dayFilter')?.value || 'all';
    var ncoOnly = document.getElementById('ncoFilter')?.checked || false;
    var highRiskOnly = document.getElementById('riskFilter')?.checked || false;

    filteredProjects = allProjects.filter(function(p) {
      if (search) {
        var s = [p.repoName, p.repo, p.sig].concat(p.lang, p.skills).join(' ').toLowerCase();
        if (s.indexOf(search) < 0) return false;
      }
      if (language !== 'all' && p.lang.indexOf(language) < 0) return false;
      if (skill !== 'all' && p.skills.indexOf(skill) < 0) return false;
      if (sig !== 'all' && p.sig !== sig) return false;
      if (day !== 'all') {
        var m = p.sigInfo && p.sigInfo.meeting;
        if (!m || !m.day || m.day.toLowerCase() !== day.toLowerCase()) return false;
      }
      if (ncoOnly && p.lf > 2) return false;
      if (highRiskOnly && p.lf > 2) return false;
      return true;
    });

    currentPage = 1;
    renderResults();
  }

  function renderResults() {
    var grid = document.getElementById('projectsGrid');
    var countEl = document.getElementById('resultsCount');
    var emptyState = document.getElementById('emptyState');
    var paginationEl = document.getElementById('pagination');
    if (!grid) return;

    var totalPages = Math.ceil(filteredProjects.length / PAGE_SIZE) || 1;
    var start = (currentPage - 1) * PAGE_SIZE;
    var pageItems = filteredProjects.slice(start, start + PAGE_SIZE);

    if (countEl) countEl.textContent = filteredProjects.length + ' of ' + allProjects.length + ' projects';

    if (filteredProjects.length === 0) {
      grid.innerHTML = '';
      if (emptyState) emptyState.classList.remove('hide');
      if (paginationEl) paginationEl.classList.add('hide');
      return;
    }
    if (emptyState) emptyState.classList.add('hide');
    grid.innerHTML = pageItems.map(renderCard).join('');

    if (paginationEl) {
      if (totalPages > 1) {
        paginationEl.classList.remove('hide');
        document.getElementById('pageInfo').textContent = 'Page ' + currentPage + ' of ' + totalPages;
        document.getElementById('prevPage').disabled = currentPage <= 1;
        document.getElementById('nextPage').disabled = currentPage >= totalPages;
      } else {
        paginationEl.classList.add('hide');
      }
    }
  }

  function renderCard(p) {
    var ncoTag = p.lf <= 2 ? '<span class="nco-tag">NCO</span>' : '';
    var lfTag = p.lf > 0 ? '<span class="risk-tag">LF ' + p.lf + '</span>' : '';
    var langBadges = p.lang.map(function(l) { return '<span class="tag">' + escapeHtml(l) + '</span>'; }).join('');
    var skillBadges = p.skills.map(function(s) { return '<span class="tag-outline">' + escapeHtml(s) + '</span>'; }).join('');

    var sigLink = '';
    if (p.sigUrl) {
      sigLink = '<a href="' + p.sigUrl + '" class="sig-link">' + escapeHtml(p.sig) + '</a>';
    } else {
      sigLink = '<span class="sig-link">' + escapeHtml(p.sig) + '</span>';
    }

    var meetingLine = '';
    if (p.sigInfo && p.sigInfo.meeting) {
      var m = p.sigInfo.meeting;
      meetingLine = '<div class="card-meeting">' + escapeHtml(m.day) + ' ' + escapeHtml(m.time) + ' ' + escapeHtml(m.tz || '') + '</div>';
    }

    var slackLink = '';
    if (p.sigInfo && p.sigInfo.slack) {
      slackLink = '<a href="https://kubernetes.slack.com/messages/' + escapeHtml(p.sigInfo.slack) + '" class="btn-sm">Slack</a>';
    }

    var gfiLink = p.gfi_url ? '<a href="' + escapeHtml(p.gfi_url) + '" class="btn-sm">Good First Issues' + (p.gfi > 0 ? ' (' + p.gfi + ')' : '') + '</a>' : '';
    var onboardingLink = p.onboarding_url ? '<a href="' + escapeHtml(p.onboarding_url) + '" class="btn-sm">Onboarding</a>' : '';

    return '<div class="project-card">' +
      '<div class="card-head">' +
        '<div><a href="https://github.com/' + escapeHtml(p.repo) + '" class="project-link">' + escapeHtml(p.repoName) + '</a></div>' +
        '<div>' + ncoTag + lfTag + '</div>' +
      '</div>' +
      '<div class="card-sig">' + sigLink + '</div>' +
      '<div class="tags-line">' + langBadges + skillBadges + '</div>' +
      meetingLine +
      '<div class="actions-line">' + gfiLink + onboardingLink + slackLink + '</div>' +
    '</div>';
  }

  function bindEvents() {
    var ids = ['searchFilter', 'languageFilter', 'skillFilter', 'sigFilter', 'dayFilter', 'ncoFilter', 'riskFilter'];
    ids.forEach(function(id) {
      var el = document.getElementById(id);
      if (!el) return;
      el.addEventListener('change', applyFilters);
      if (el.type === 'text') el.addEventListener('input', debounce(applyFilters, 300));
    });

    var prev = document.getElementById('prevPage');
    var next = document.getElementById('nextPage');
    if (prev) prev.addEventListener('click', function() { if (currentPage > 1) { currentPage--; renderResults(); } });
    if (next) next.addEventListener('click', function() { var total = Math.ceil(filteredProjects.length / PAGE_SIZE); if (currentPage < total) { currentPage++; renderResults(); } });

    var clearBtn = document.getElementById('clearFilters');
    var resetBtn = document.getElementById('resetFiltersBtn');
    if (clearBtn) clearBtn.addEventListener('click', clearFilters);
    if (resetBtn) resetBtn.addEventListener('click', clearFilters);
  }

  function clearFilters() {
    var el;
    el = document.getElementById('searchFilter'); if (el) el.value = '';
    el = document.getElementById('languageFilter'); if (el) el.value = 'all';
    el = document.getElementById('skillFilter'); if (el) el.value = 'all';
    el = document.getElementById('sigFilter'); if (el) el.value = 'all';
    el = document.getElementById('dayFilter'); if (el) el.value = 'all';
    el = document.getElementById('ncoFilter'); if (el) el.checked = false;
    el = document.getElementById('riskFilter'); if (el) el.checked = false;
    applyFilters();
  }

  function debounce(fn, ms) {
    var timer;
    return function() { clearTimeout(timer); timer = setTimeout(fn, ms); };
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
