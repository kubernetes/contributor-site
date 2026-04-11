(function () {
  const chartDom = document.getElementById('lotteryTreemap');
  if (!chartDom) return;
  const myChart = echarts.init(chartDom);

  fetch('/data/lottery_factor.json')
    .then(response => response.json())
    .then(data => {
      const lastUpdatedEl = document.getElementById('lastUpdated');
      if (lastUpdatedEl && data.repo_data.length > 0) {
        lastUpdatedEl.innerText = 'Last updated: ' + new Date(data.repo_data[0].last_updated).toLocaleString();
      }

      const formattedData = data.subprojects.map(sub => {
        const subData = {
          name: sub.name,
          children: sub.repos.map(repoName => {
            const stats = data.repo_data.find(r => r.repo === repoName);
            if (!stats) return null;

            // Map Lottery Factor to color
            let color = '#28a745'; // Green
            if (stats.lottery_factor <= 2) color = '#dc3545'; // Red
            else if (stats.lottery_factor <= 4) color = '#ffc107'; // Yellow

            return {
              name: repoName,
              value: stats.total_points,
              lotteryFactor: stats.lottery_factor,
              itemStyle: { color: color },
              contributors: stats.contributors.slice(0, 10)
            };
          }).filter(r => r !== null)
        };
        return subData;
      });

      const option = {
        title: {
          text: 'SIG ContribEx Lottery Factor Treemap',
          left: 'center'
        },
        tooltip: {
          confine: true,
          formatter: function (info) {
            const stats = info.data;
            if (!stats || !stats.contributors) return info.name;

            // Limit to top 5 in tooltip for readability
            const displayContribs = stats.contributors.slice(0, 5);
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
                ${contribList}
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
            label: {
              show: true,
              formatter: '{b}\n(LF: {c})',
              rich: {
                // placeholder
              }
            },
            upperLabel: {
              show: true,
              height: 30
            },
            itemStyle: {
              borderColor: '#fff'
            },
            levels: [
              {
                itemStyle: {
                  borderWidth: 0,
                  gapWidth: 5
                }
              },
              {
                itemStyle: {
                  gapWidth: 1
                }
              },
              {
                colorSaturation: [0.35, 0.5],
                itemStyle: {
                  gapWidth: 1,
                  borderColorSaturation: 0.6
                }
              }
            ],
            data: formattedData
          }
        ]
      };

      myChart.setOption(option);

      myChart.on('click', function (params) {
        if (!params.data || !params.data.name) return;
        const stats = data.repo_data.find(r => r.repo === params.data.name);
        if (stats) {
          const modalBody = document.getElementById('projectInfoBody');

          const topContributors = stats.contributors.slice(0, 10).map(c =>
            `<li><a href="https://github.com/${c.author}" target="_blank" class="text-decoration-none">@${c.author}</a> (${c.points} pts)</li>`
          ).join('');

          const approvers = (stats.owners.approvers || []).map(a =>
            `<a href="https://github.com/${a}" target="_blank" class="badge bg-primary bg-opacity-10 text-primary text-decoration-none me-1 mb-1">@${a}</a>`
          ).join('');

          const reviewers = (stats.owners.reviewers || []).map(r =>
            `<a href="https://github.com/${r}" target="_blank" class="badge bg-secondary bg-opacity-10 text-secondary text-decoration-none me-1 mb-1">@${r}</a>`
          ).join('');

          const techStack = (stats.tech_stack || []).map(lang =>
            `<span class="badge border text-dark me-1">${lang}</span>`
          ).join('');

          // Use properties from JSON, fallback to repo root if missing
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
            <div class="mt-3 p-2 bg-light rounded border">
              <div class="d-flex justify-content-between align-items-center">
                <span><strong>Lottery Factor:</strong> <span class="badge bg-${stats.lottery_factor <= 2 ? 'danger' : (stats.lottery_factor <= 4 ? 'warning text-dark' : 'success')}">${stats.lottery_factor}</span></span>
                <span class="small text-muted"><strong>SIG in charge:</strong> Contributor Experience</span>
              </div>
            </div>
          `;

          document.getElementById('projectInfoModalLabel').innerText = stats.repo;
          const modalElement = document.getElementById('projectInfoModal');
          const modal = bootstrap.Modal.getOrCreateInstance(modalElement);
          modal.show();
        }
      });
    })
    .catch(err => console.error('Error loading lottery factor data:', err));

  window.addEventListener('resize', () => myChart.resize());
})();
