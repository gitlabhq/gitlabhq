class FilteredSearchSpecHelper {
  static createFilterVisualTokenHTML(name, value) {
    return `
      <li class="js-visual-token filtered-search-token">
        <div class="name">${name}</div>
        <div class="value">${value}</div>
      </li>
    `;
  }

  static createNameFilterVisualTokenHTML(name) {
    return `
      <li class="js-visual-token filtered-search-token">
        <div class="name">${name}</div>
      </li>
    `;
  }

  static createSearchVisualTokenHTML(name) {
    return `
      <li class="js-visual-token filtered-search-term">
        <div class="name">${name}</div>
      </li>
    `;
  }
}

module.exports = FilteredSearchSpecHelper;
