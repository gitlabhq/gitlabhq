import $ from 'jquery';
import Api from '~/api';
import Search from '~/pages/search/show/search';

describe('Search', () => {
  const fixturePath = 'search/show.html.raw';
  const searchTerm = 'some search';
  const fillDropdownInput = (dropdownSelector) => {
    const dropdownElement = document.querySelector(dropdownSelector).parentNode;
    const inputElement = dropdownElement.querySelector('.dropdown-input-field');
    inputElement.value = searchTerm;
    return inputElement;
  };

  preloadFixtures(fixturePath);

  beforeEach(() => {
    loadFixtures(fixturePath);
    new Search(); // eslint-disable-line no-new
  });

  it('requests groups from backend when filtering', (done) => {
    spyOn(Api, 'groups').and.callFake((term) => {
      expect(term).toBe(searchTerm);
      done();
    });
    const inputElement = fillDropdownInput('.js-search-group-dropdown');

    $(inputElement).trigger('input');
  });

  it('requests projects from backend when filtering', (done) => {
    spyOn(Api, 'projects').and.callFake((term) => {
      expect(term).toBe(searchTerm);
      done();
    });
    const inputElement = fillDropdownInput('.js-search-project-dropdown');

    $(inputElement).trigger('input');
  });
});
