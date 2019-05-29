import Vue from 'vue';
import _ from 'underscore';
import ProjectSelector from '~/vue_shared/components/project_selector/project_selector.vue';
import ProjectListItem from '~/vue_shared/components/project_selector/project_list_item.vue';
import { shallowMount } from '@vue/test-utils';
import { trimText } from 'spec/helpers/text_helper';

describe('ProjectSelector component', () => {
  let wrapper;
  let vm;
  loadJSONFixtures('static/projects.json');
  const allProjects = getJSONFixture('static/projects.json');
  const searchResults = allProjects.slice(0, 5);
  let selected = [];
  selected = selected.concat(allProjects.slice(0, 3)).concat(allProjects.slice(5, 8));

  beforeEach(() => {
    jasmine.clock().install();

    wrapper = shallowMount(Vue.extend(ProjectSelector), {
      propsData: {
        projectSearchResults: searchResults,
        selectedProjects: selected,
        showNoResultsMessage: false,
        showMinimumSearchQueryMessage: false,
        showLoadingIndicator: false,
        showSearchErrorMessage: false,
      },
      attachToDocument: true,
    });

    ({ vm } = wrapper);
  });

  afterEach(() => {
    jasmine.clock().uninstall();
    vm.$destroy();
  });

  it('renders the search results', () => {
    expect(wrapper.findAll('.js-project-list-item').length).toBe(5);
  });

  it(`triggers a (debounced) search when the search input value changes`, () => {
    spyOn(vm, '$emit');
    const query = 'my test query!';
    const searchInput = wrapper.find('.js-project-selector-input');
    searchInput.setValue(query);
    searchInput.trigger('input');

    expect(vm.$emit).not.toHaveBeenCalledWith();
    jasmine.clock().tick(501);

    expect(vm.$emit).toHaveBeenCalledWith('searched', query);
  });

  it(`debounces the search input`, () => {
    spyOn(vm, '$emit');
    const searchInput = wrapper.find('.js-project-selector-input');

    const updateSearchQuery = (count = 0) => {
      if (count === 10) {
        jasmine.clock().tick(101);

        expect(vm.$emit).toHaveBeenCalledTimes(1);
        expect(vm.$emit).toHaveBeenCalledWith('searched', `search query #9`);
      } else {
        searchInput.setValue(`search query #${count}`);
        searchInput.trigger('input');

        jasmine.clock().tick(400);
        updateSearchQuery(count + 1);
      }
    };

    updateSearchQuery();
  });

  it(`includes a placeholder in the search box`, () => {
    expect(wrapper.find('.js-project-selector-input').attributes('placeholder')).toBe(
      'Search your projects',
    );
  });

  it(`triggers a "projectClicked" event when a project is clicked`, () => {
    spyOn(vm, '$emit');
    wrapper.find(ProjectListItem).vm.$emit('click', _.first(searchResults));

    expect(vm.$emit).toHaveBeenCalledWith('projectClicked', _.first(searchResults));
  });

  it(`shows a "no results" message if showNoResultsMessage === true`, () => {
    wrapper.setProps({ showNoResultsMessage: true });

    expect(wrapper.contains('.js-no-results-message')).toBe(true);

    const noResultsEl = wrapper.find('.js-no-results-message');

    expect(trimText(noResultsEl.text())).toEqual('Sorry, no projects matched your search');
  });

  it(`shows a "minimum search query" message if showMinimumSearchQueryMessage === true`, () => {
    wrapper.setProps({ showMinimumSearchQueryMessage: true });

    expect(wrapper.contains('.js-minimum-search-query-message')).toBe(true);

    const minimumSearchEl = wrapper.find('.js-minimum-search-query-message');

    expect(trimText(minimumSearchEl.text())).toEqual('Enter at least three characters to search');
  });

  it(`shows a error message if showSearchErrorMessage === true`, () => {
    wrapper.setProps({ showSearchErrorMessage: true });

    expect(wrapper.contains('.js-search-error-message')).toBe(true);

    const errorMessageEl = wrapper.find('.js-search-error-message');

    expect(trimText(errorMessageEl.text())).toEqual(
      'Something went wrong, unable to search projects',
    );
  });

  it(`focuses the input element when the focusSearchInput() method is called`, () => {
    const input = wrapper.find('.js-project-selector-input');

    expect(document.activeElement).not.toBe(input.element);
    vm.focusSearchInput();

    expect(document.activeElement).toBe(input.element);
  });
});
