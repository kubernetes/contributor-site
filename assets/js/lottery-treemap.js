(function () {
  const chartDom = document.getElementById('lotteryTreemap');
  if (!chartDom) return;
  const myChart = echarts.init(chartDom);

  const modalFooter = document.getElementById('projectInfoModalFooter');
  if (modalFooter) {
    modalFooter.innerHTML = '<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>';
  }

  const initChart = (data) => {
    const lastUpdatedEl = document.getElementById('lastUpdated');
    if (lastUpdatedEl && data.repo_data.length > 0) {
      lastUpdatedEl.innerText = 'Last updated: ' + new Date(data.repo_data[0].last_updated).toLocaleString();
    }

    const sigNames = data.sigs.map(s => s.name).join(' & ');

    const formattedData = data.sigs.map(sig => {
      return {
        name: sig.name,
        children: sig.subprojects.map(sub => {
          return {
            name: sub.name,
            children: sub.repos.map(repoName => {
              const stats = data.repo_data.find(r => r.repo === repoName);
              if (!stats) return null;

              let color = '#1a9641';
              if (stats.lottery_factor <= 2) color = '#d7191c';
              else if (stats.lottery_factor <= 4) color = '#fdae61';

              const contributors = stats.contributors || [];

              return {
                name: repoName,
                value: stats.total_points,
                lotteryFactor: stats.lottery_factor,
                itemStyle: { color: color },
                contributors: contributors.slice(0, 10)
              };
            }).filter(r => r !== null)
          };
        }).filter(s => s.children.length > 0)
      };
    });

    const option = {
      title: {
        text: `${sigNames} Community Resilience`,
        left: 'center'
      },
      tooltip: {
        confine: true,
        formatter: function (info) {
          const stats = info.data;
          if (!stats || !stats.contributors) return info.name;

          const contributors = stats.contributors || [];
          const displayContribs = contributors.slice(0, 5);
          const contribList = displayContribs.map(c =>
            `<div style="display:flex; justify-content:space-between; gap: 15px; font-size: 11px;">
              <span>@${c.author}</span>
              <span style="font-weight:bold">${c.points}</span>
            </div>`
          ).join('');

          return `
            <div style="border-bottom: 1px solid rgba(255,255,255,.3); padding-bottom: 4px; margin-bottom: 4px;">
              <b style="font-size: 13px;">${info.name}</b>
            </div>
            <div style="margin-bottom: 8px; font-size: 12px;">
              Lottery Factor: <b style="color: ${stats.lotteryFactor <= 2 ? '#ff4d4f' : '#faad14'}">${stats.lotteryFactor}</b><br/>
              Activity Score: <b>${info.value}</b>
            </div>
            <div style="font-size: 11px;">
              <div style="color: #ccc; margin-bottom: 2px; text-transform: uppercase; letter-spacing: 0.5px;">Top Contributors:</div>
              ${contribList.length > 0 ? contribList : '<div class="text-muted small">No recent activity</div>'}
              <div style="color: #aaa; font-style: italic; margin-top: 4px; border-top: 1px solid rgba(255,255,255,0.1); padding-top: 4px;">Click for maintainers & stack</div>
            </div>
          `;
        }
      },
      series: [
        {
          name: 'Lottery Factor',
          type: 'treemap',
          visibleMin: 300,
          zoomLimit: { min: 1, max: 3 },
          label: {
            show: true,
            formatter: '{b}\n(LF: {c})',
          },
          upperLabel: {
            show: true,
            height: 30
          },
          itemStyle: {
            borderColor: '#fff'
          },
          breadcrumb: {
            show: true
          },
          levels: [
            {
              itemStyle: { borderWidth: 0, gapWidth: 5 }
            },
            {
              itemStyle: { gapWidth: 1 }
            },
            {
              itemStyle: { gapWidth: 1 }
            }
          ],
          data: formattedData
        }
      ]
    };

    myChart.setOption(option);

    myChart.on('click', function (params) {
      if (!params.data || !params.data.name || !params.data.contributors) return;
      const stats = data.repo_data.find(r => r.repo === params.data.name);
      if (stats) {
        const modalBody = document.getElementById('projectInfoBody');
        const contributors = stats.contributors || [];
        const owners = stats.owners || { approvers: [], reviewers: [] };
        const sigsInCharge = (stats.sigs || []).join(', ') || 'N/A';
        const subprojects = (stats.subprojects || []).join(', ') || 'N/A';

        const topContributors = contributors.slice(0, 10).map(c =>
          `<li><a href="https://github.com/${c.author}" target="_blank" class="text-decoration-none">@${c.author}</a> (${c.points} pts)</li>`
        ).join('') || '<li class="text-muted small">No recent activity detected</li>';

        const approvers = (owners.approvers || []).map(a =>
          `<a href="https://github.com/${a}" target="_blank" class="badge bg-primary bg-opacity-10 text-primary text-decoration-none me-1 mb-1">@${a}</a>`
        ).join('');

        const reviewers = (owners.reviewers || []).map(r =>
          `<a href="https://github.com/${r}" target="_blank" class="badge bg-secondary bg-opacity-10 text-secondary text-decoration-none me-1 mb-1">@${r}</a>`
        ).join('');

        const techStack = (stats.tech_stack || []).map(lang =>
          `<span class="badge border text-dark me-1">${lang}</span>`
        ).join('');

        const onboardingUrl = stats.onboarding_url || `https://github.com/${stats.repo}`;
        const ownersUrl = stats.owners_url || `https://github.com/${stats.repo}/blob/main/OWNERS`;
        const issuesUrl = stats.issues_url || `https://github.com/${stats.repo}/issues`;
        const goodFirstIssuesUrl = stats.good_first_issues_url || `${issuesUrl}?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22`;

        modalBody.innerHTML = `
          <div class="row">
            <div class="col-md-7">
              <div class="mb-3">
                <h6 class="fw-bold text-uppercase small text-muted">Tech Stack</h6>
                <div>${techStack || '<span class="text-muted small">Not detected</span>'}</div>
              </div>
              <div class="mb-3">
                <h6 class="fw-bold text-uppercase small text-muted">Resources</h6>
                <ul class="list-unstyled">
                  <li class="mb-1"><a href="https://github.com/${stats.repo}" target="_blank" class="text-decoration-none"><i class="fab fa-github me-2"></i>Repository</a></li>
                  <li class="mb-1"><a href="${onboardingUrl}" target="_blank" class="text-decoration-none"><i class="fas fa-book-open me-2"></i>Onboarding Guide</a></li>
                  <li class="mb-1"><a href="${ownersUrl}" target="_blank" class="text-decoration-none"><i class="fas fa-users me-2"></i>Project OWNERS</a></li>
                  <li class="mb-1"><a href="${issuesUrl}" target="_blank" class="text-decoration-none"><i class="fas fa-exclamation-circle me-2"></i>Open Issues</a></li>
                  <li class="mb-1"><a href="${goodFirstIssuesUrl}" target="_blank" class="text-decoration-none text-success"><i class="fas fa-seedling me-2"></i>Good First Issues</a></li>
                </ul>
              </div>
              <div class="mb-3">
                <h6 class="fw-bold text-uppercase small text-muted">Maintainers (Approvers)</h6>
                <div class="d-flex flex-wrap">${approvers || '<span class="text-muted small">See OWNERS file</span>'}</div>
              </div>
              <div>
                <h6 class="fw-bold text-uppercase small text-muted">Reviewers</h6>
                <div class="d-flex flex-wrap">${reviewers || '<span class="text-muted small">See OWNERS file</span>'}</div>
              </div>
            </div>
            <div class="col-md-5 border-start">
              <h6 class="fw-bold text-uppercase small text-muted">Active Contributors (6mo)</h6>
              <ul class="small list-unstyled">
                ${topContributors}
              </ul>
            </div>
          </div>
          <div class="mt-3 p-3 bg-light rounded border">
             <div class="row g-2">
                <div class="col-12">
                   <div class="d-flex justify-content-between align-items-center mb-2">
                      <span><strong>Lottery Factor:</strong> <span class="badge bg-${stats.lottery_factor <= 2 ? 'danger' : (stats.lottery_factor <= 4 ? 'warning text-dark' : 'success')}">${stats.lottery_factor}</span></span>
                      <span class="small text-muted"><strong>Activity Score:</strong> ${stats.total_points}</span>
                   </div>
                </div>
                <div class="col-12 border-top pt-2">
                   <div class="small text-muted mb-1"><strong>SIG(s):</strong> ${sigsInCharge}</div>
                   <div class="small text-muted"><strong>Subproject(s):</strong> ${subprojects}</div>
                </div>
             </div>
          </div>
        `;

        document.getElementById('projectInfoModalLabel').innerText = stats.repo;
        const modalElement = document.getElementById('projectInfoModal');
        const modal = bootstrap.Modal.getOrCreateInstance(modalElement);
        modal.show();
      }
    });
  };

  if (window.lotteryData) {
    initChart(window.lotteryData);
  } else {
    fetch('/data/lottery_factor.json')
      .then(response => response.json())
      .then(data => initChart(data))
      .catch(err => console.error('Error loading lottery factor data:', err));
  }

  window.addEventListener('resize', () => myChart.resize());
})();
