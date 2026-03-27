document.addEventListener('DOMContentLoaded', function() {
  const searchInput = document.getElementById('sigSearchInput');
  const dayFilter = document.getElementById('dayFilter');
  const cardWrappers = document.querySelectorAll('.sig-card-wrapper');
  const topicTags = document.querySelectorAll('.topic-tag');
  const clearBtn = document.getElementById('clearFilters');
  
  function applyFilters() {
    const searchTerm = searchInput ? searchInput.value.toLowerCase().trim() : '';
    const dayTerm = dayFilter ? dayFilter.value.toLowerCase() : '';
    
    if (clearBtn) {
      if (searchTerm !== '' || dayTerm !== '') {
        clearBtn.classList.remove('d-none');
      } else {
        clearBtn.classList.add('d-none');
      }
    }

    cardWrappers.forEach(wrapper => {
      const name = wrapper.dataset.name || '';
      const desc = wrapper.dataset.description || '';
      const label = wrapper.dataset.label || '';
      const days = wrapper.dataset.days || '';
      
      const matchesSearch = name.includes(searchTerm) || desc.includes(searchTerm) || label.includes(searchTerm);
      const matchesDay = dayTerm === '' || days.includes(dayTerm);
      
      if (matchesSearch && matchesDay) {
        wrapper.classList.remove('d-none');
      } else {
        wrapper.classList.add('d-none');
      }
    });

    // Update active state of tags
    topicTags.forEach(tag => {
      if (searchTerm === tag.dataset.tag) {
        tag.classList.add('active');
      } else {
        tag.classList.remove('active');
      }
    });
  }
  
  if(searchInput) searchInput.addEventListener('input', applyFilters);
  if(dayFilter) dayFilter.addEventListener('change', applyFilters);
  
  topicTags.forEach(tag => {
    tag.addEventListener('click', () => {
      if(searchInput) {
        searchInput.value = tag.dataset.tag;
        applyFilters();
      }
    });
  });

  if(clearBtn) {
    clearBtn.addEventListener('click', () => {
      if(searchInput) searchInput.value = '';
      if(dayFilter) dayFilter.value = '';
      applyFilters();
    });
  }

  // Handle URL hash for tab activation
  if (window.location.hash) {
    const hash = window.location.hash;
    const tabEl = document.querySelector(`button[data-bs-target="${hash}"]`);
    if (tabEl) {
      // Check if bootstrap is available
      if (typeof bootstrap !== 'undefined') {
        const tab = new bootstrap.Tab(tabEl);
        tab.show();
      }
    }
  }

  // Handle Expand/Collapse toggle text and icons
  const collapsibles = document.querySelectorAll('.collapse');
  collapsibles.forEach(coll => {
    coll.addEventListener('show.bs.collapse', function (e) {
      const btn = document.querySelector(`[data-bs-target="#${e.target.id}"]`);
      if(btn) {
        const icon = btn.querySelector('.toggle-icon');
        const text = btn.querySelector('.toggle-text');
        if(icon) { icon.classList.remove('fa-chevron-down'); icon.classList.add('fa-chevron-up'); }
        if(text) { text.textContent = 'Hide Details'; }
      }
    });
    coll.addEventListener('hide.bs.collapse', function (e) {
      const btn = document.querySelector(`[data-bs-target="#${e.target.id}"]`);
      if(btn) {
        const icon = btn.querySelector('.toggle-icon');
        const text = btn.querySelector('.toggle-text');
        if(icon) { icon.classList.remove('fa-chevron-up'); icon.classList.add('fa-chevron-down'); }
        if(text) { text.textContent = 'Show Details'; }
      }
    });
  });
});
