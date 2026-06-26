(function() {
  'use strict';

  var PAGE_SIZE = 12;
  var MAX_VISIBLE_PAGES = 7;

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
  var filters = { language: 'all', skill: 'all', sig: 'all', day: 'all', nco: false, risk: false };

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
        return {
          name: s.name, dir: s.dir || '',
          meeting: s.meetings && s.meetings.length > 0 ? s.meetings[0] : null,
          slack: s.contact ? s.contact.slack : null,
          description: s.mission_statement || ''
        };
      }
    }
    return null;
  }

  function sigPageUrl(info) {
    if (!info || !info.dir) return '';
    return '/community/community-groups/sigs/' + info.dir.replace(/^sig-/, '') + '/';
  }

  function buildProjects() {
    var data = window.lotteryFactorData;
    var result = [];

    if (hasRealData(data)) {
      for (var i = 0; i < data.length; i++) {
        var r = data[i];
        var ts = r.tech_stack || {};
        var name = (r.sigs || [])[0] || '';
        var info = findSigInfo(name);
        result.push({
          repo: r.repo, repoName: r.repo.split('/')[1], sig: name, sigInfo: info,
          sigUrl: sigPageUrl(info), lang: ts.languages || [], skills: ts.skills_needed || [],
          lf: r.lottery_factor || 0, gfi: ts.good_first_issue_count || 0,
          gfi_url: r.good_first_issues_url || '', onboarding_url: r.onboarding_url || '',
        });
      }
    }

    if (result.length === 0) {
      result = SAMPLE_PROJECTS.map(function(s) {
        var info = findSigInfo(s.sig);
        return {
          repo: s.repo, repoName: s.repo.split('/')[1], sig: s.sig, sigInfo: info,
          sigUrl: sigPageUrl(info), lang: s.lang, skills: s.skills, lf: s.lf, gfi: s.gfi,
          gfi_url: 'https://github.com/' + s.repo + '/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22',
          onboarding_url: 'https://github.com/' + s.repo + '/blob/main/CONTRIBUTING.md',
        };
      });
    }

    result.sort(function(a, b) { return a.lf - b.lf; });
    return result;
  }

  function init() {
    if (!document.getElementById('projectsGrid')) return;
    allProjects = buildProjects();
    bindPills();
    bindClear();
    applyFilters();
  }

  function getFilterVal(group) {
    if (group === 'nco') return filters.nco;
    if (group === 'risk') return filters.risk;
    return filters[group] || 'all';
  }

  function setFilterVal(group, val) {
    if (group === 'nco' || group === 'risk') {
      filters[group] = !filters[group];
    } else {
      if (filters[group] === val) { filters[group] = 'all'; } else { filters[group] = val; }
    }
  }

  function updatePillUI() {
    document.querySelectorAll('.pill').forEach(function(p) {
      var group = p.getAttribute('data-filter');
      var val = p.getAttribute('data-value');
      if (!group) return;
      var current = getFilterVal(group);
      var isActive = (current === val) || (group === 'nco' && val === '1' && filters.nco) || (group === 'risk' && val === '1' && filters.risk);
      p.classList.toggle('active', isActive);
    });
  }

  function applyFilters() {
    var search = (document.getElementById('searchFilter')?.value || '').toLowerCase().trim();

    filteredProjects = allProjects.filter(function(p) {
      if (search) {
        var s = [p.repoName, p.repo, p.sig].concat(p.lang, p.skills).join(' ').toLowerCase();
        if (s.indexOf(search) < 0) return false;
      }
      if (filters.language !== 'all' && p.lang.indexOf(filters.language) < 0) return false;
      if (filters.skill !== 'all' && p.skills.indexOf(filters.skill) < 0) return false;
      if (filters.sig !== 'all' && p.sig !== filters.sig) return false;
      if (filters.day !== 'all') {
        var m = p.sigInfo && p.sigInfo.meeting;
        if (!m || !m.day || m.day.toLowerCase() !== filters.day) return false;
      }
      if (filters.nco && p.lf > 2) return false;
      if (filters.risk && p.lf > 2) return false;
      return true;
    });

    currentPage = 1;
    updatePillUI();
    renderResults();
  }

  function renderResults() {
    var grid = document.getElementById('projectsGrid');
    var countEl = document.getElementById('resultsCount');
    var emptyState = document.getElementById('emptyState');
    var pagEl = document.getElementById('pagination');
    if (!grid) return;

    var totalPages = Math.ceil(filteredProjects.length / PAGE_SIZE) || 1;
    var start = (currentPage - 1) * PAGE_SIZE;
    var pageItems = filteredProjects.slice(start, start + PAGE_SIZE);

    if (countEl) countEl.textContent = filteredProjects.length + ' of ' + allProjects.length + ' projects';

    if (filteredProjects.length === 0) {
      grid.innerHTML = '';
      if (emptyState) emptyState.classList.remove('hide');
      if (pagEl) pagEl.innerHTML = '';
      return;
    }
    if (emptyState) emptyState.classList.add('hide');
    grid.innerHTML = pageItems.map(renderCard).join('');
    renderPagination(pagEl, totalPages);
  }

  function renderCard(p) {
    var tags = [];
    if (p.lf <= 2) tags.push('<span class="tag-badge lf-' + p.lf + '">NCO</span>');
    if (p.lf > 0) tags.push('<span class="tag-badge lf-' + p.lf + '">LF ' + p.lf + '</span>');
    var badgeHtml = tags.join('');

    var langHtml = p.lang.map(function(l) { return '<span class="lang-tag">' + escapeHtml(l) + '</span>'; }).join('');
    var skillHtml = p.skills.map(function(s) { return '<span class="skill-tag">' + escapeHtml(s) + '</span>'; }).join('');

    var sigHtml = p.sigUrl ? '<a href="' + p.sigUrl + '" class="sig-link">' + escapeHtml(p.sig) + '</a>' : '<span class="sig-link">' + escapeHtml(p.sig) + '</span>';

    var meeting = '';
    if (p.sigInfo && p.sigInfo.meeting) {
      var m = p.sigInfo.meeting;
      meeting = '<div class="card-meeting">' + escapeHtml(m.day) + ' ' + escapeHtml(m.time) + ' ' + escapeHtml(m.tz || '') + '</div>';
    }

    var slack = p.sigInfo && p.sigInfo.slack ? '<a href="https://kubernetes.slack.com/messages/' + escapeHtml(p.sigInfo.slack) + '" class="action-link">Slack</a>' : '';
    var gfi = p.gfi_url ? '<a href="' + escapeHtml(p.gfi_url) + '" class="action-link">Good First Issues' + (p.gfi > 0 ? ' (' + p.gfi + ')' : '') + '</a>' : '';
    var ob = p.onboarding_url ? '<a href="' + escapeHtml(p.onboarding_url) + '" class="action-link">Onboarding</a>' : '';

    return '<div class="project-card">' +
      '<div class="card-head"><div><a href="https://github.com/' + escapeHtml(p.repo) + '" class="project-link">' + escapeHtml(p.repoName) + '</a></div><div>' + badgeHtml + '</div></div>' +
      '<div class="card-sig">' + sigHtml + '</div>' +
      '<div class="tags-line">' + langHtml + skillHtml + '</div>' +
      meeting +
      '<div class="actions-line">' + gfi + ob + slack + '</div>' +
    '</div>';
  }

  function renderPagination(el, total) {
    if (!el) return;
    if (total <= 1) { el.innerHTML = ''; return; }

    var html = '';

    html += '<button class="page-btn" data-page="' + (currentPage - 1) + '"' + (currentPage <= 1 ? ' disabled' : '') + '>&#8592;</button>';

    var pages = [];
    if (total <= MAX_VISIBLE_PAGES) {
      for (var i = 1; i <= total; i++) pages.push(i);
    } else {
      pages.push(1);
      var startPage = Math.max(2, currentPage - 2);
      var endPage = Math.min(total - 1, currentPage + 2);
      if (startPage > 2) pages.push('...');
      for (var i = startPage; i <= endPage; i++) pages.push(i);
      if (endPage < total - 1) pages.push('...');
      pages.push(total);
    }

    pages.forEach(function(p) {
      if (p === '...') {
        html += '<span class="page-dots">...</span>';
      } else {
        html += '<button class="page-btn' + (p === currentPage ? ' current' : '') + '" data-page="' + p + '">' + p + '</button>';
      }
    });

    html += '<button class="page-btn" data-page="' + (currentPage + 1) + '"' + (currentPage >= total ? ' disabled' : '') + '>&#8594;</button>';

    el.innerHTML = html;

    el.querySelectorAll('.page-btn:not(.current):not(:disabled)').forEach(function(btn) {
      btn.addEventListener('click', function() {
        var page = parseInt(this.getAttribute('data-page'));
        if (page >= 1 && page <= total) {
          currentPage = page;
          renderResults();
          document.getElementById('projectsGrid').scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
      });
    });
  }

  function bindPills() {
    document.querySelectorAll('.pill').forEach(function(p) {
      p.addEventListener('click', function() {
        var group = this.getAttribute('data-filter');
        var val = this.getAttribute('data-value');
        if (!group) return;
        setFilterVal(group, val);
        applyFilters();
      });
    });

    var searchInput = document.getElementById('searchFilter');
    if (searchInput) {
      searchInput.addEventListener('input', debounce(applyFilters, 250));
    }
  }

  function bindClear() {
    var clearBtn = document.getElementById('clearFilters');
    var resetBtn = document.getElementById('resetFiltersBtn');
    var cb = function() {
      filters = { language: 'all', skill: 'all', sig: 'all', day: 'all', nco: false, risk: false };
      var si = document.getElementById('searchFilter');
      if (si) si.value = '';
      applyFilters();
    };
    if (clearBtn) clearBtn.addEventListener('click', cb);
    if (resetBtn) resetBtn.addEventListener('click', cb);
  }

  function debounce(fn, ms) { var t; return function() { clearTimeout(t); t = setTimeout(fn, ms); }; }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
