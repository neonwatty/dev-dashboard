// Mobile Filters Stimulus Controller Enhancement
document.addEventListener('DOMContentLoaded', function() {
  // Add mobile filter toggle functionality if the stimulus controller doesn't handle it
  const sourceFiltersController = document.querySelector('[data-controller*="source-filters"]');
  
  if (sourceFiltersController && !sourceFiltersController.hasOwnProperty('toggleMobileFilters')) {
    // Add mobile toggle functionality
    const mobileToggle = sourceFiltersController.querySelector('[data-source-filters-target="mobileToggle"]');
    const filterPanel = sourceFiltersController.querySelector('[data-source-filters-target="filterPanel"]');
    const chevron = sourceFiltersController.querySelector('[data-source-filters-target="chevron"]');
    const activeCount = sourceFiltersController.querySelector('[data-source-filters-target="activeCount"]');
    
    if (mobileToggle && filterPanel && chevron) {
      // Update active filter count
      function updateActiveFilterCount() {
        const urlParams = new URLSearchParams(window.location.search);
        const activeFilters = [];
        
        if (urlParams.get('keyword')) activeFilters.push('Search');
        if (urlParams.get('status')) activeFilters.push('Status');
        if (urlParams.get('tag')) activeFilters.push('Tag');
        if (urlParams.get('sources')) activeFilters.push('Sources');
        if (urlParams.get('min_priority')) activeFilters.push('Priority');
        if (urlParams.get('after_date')) activeFilters.push('Date');
        
        if (activeCount) {
          activeCount.textContent = activeFilters.length > 0 ? `${activeFilters.length} active` : '';
        }
      }
      
      // Toggle filter panel
      mobileToggle.addEventListener('click', function() {
        const isHidden = filterPanel.classList.contains('hidden');
        
        if (isHidden) {
          filterPanel.classList.remove('hidden');
          filterPanel.classList.add('md:block');
          chevron.style.transform = 'rotate(180deg)';
        } else {
          filterPanel.classList.add('hidden');
          filterPanel.classList.remove('md:block');
          chevron.style.transform = 'rotate(0deg)';
        }
      });
      
      // Initialize
      updateActiveFilterCount();
      
      // Update count when filters change
      window.addEventListener('popstate', updateActiveFilterCount);
    }
  }
});