import Vue from 'vue';
import _ from 'underscore';
import ProjectSelector from '~/vue_shared/components/project_selector/project_selector.vue';
import ProjectListItem from '~/vue_shared/components/project_selector/project_list_item.vue';
import { shallowMount } from '@vue/test-utils';
import { trimText } from 'spec/helpers/vue_component_helper';

describe('ProjectSelector component', () => {
  let wrapper;
  let vm;
  loadJSONFixtures('projects.json');
  const allProjects = getJSONFixture('projects.json');
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
    expect(vm.$el.querySelectorAll('.js-project-list-item').length).toBe(5);
  });

  it(`triggers a (debounced) search when the search input value changes`, done => {
    spyOn(vm, '$emit');
    const query = 'my test query!';
    const searchInput = vm.$el.querySelector('.js-project-selector-input');
    searchInput.value = query;
    searchInput.dispatchEvent(new Event('input'));

    vm.$nextTick(() => {
      expect(vm.$emit).not.toHaveBeenCalledWith();
      jasmine.clock().tick(501);

      expect(vm.$emit).toHaveBeenCalledWith('searched', query);
      done();
    });
  });

  it(`debounces the search input`, done => {
    spyOn(vm, '$emit');
    const searchInput = vm.$el.querySelector('.js-project-selector-input');

    const updateSearchQuery = (count = 0) => {
      if (count === 10) {
        jasmine.clock().tick(101);

        expect(vm.$emit).toHaveBeenCalledTimes(1);
        expect(vm.$emit).toHaveBeenCalledWith('searched', `search query #9`);
        done();
      } else {
        searchInput.value = `search query #${count}`;
        searchInput.dispatchEvent(new Event('input'));

        vm.$nextTick(() => {
          jasmine.clock().tick(400);
          updateSearchQuery(count + 1);
        });
      }
    };

    updateSearchQuery();
  });

  it(`includes a placeholder in the search box`, () => {
    expect(vm.$el.querySelector('.js-project-selector-input').placeholder).toBe(
      'Search your projects',
    );
  });

  it(`triggers a "projectClicked" event when a project is clicked`, () => {
    spyOn(vm, '$emit');
    wrapper.find(ProjectListItem).vm.$emit('click', _.first(searchResults));

    expect(vm.$emit).toHaveBeenCalledWith('projectClicked', _.first(searchResults));
  });

  it(`shows a "no results" message if showNoResultsMessage === true`, done => {
    wrapper.setProps({ showNoResultsMessage: true });

    vm.$nextTick(() => {
      const noResultsEl = vm.$el.querySelector('.js-no-results-message');

      expect(noResultsEl).toBeTruthy();

      expect(trimText(noResultsEl.textContent)).toEqual('Sorry, no projects matched your search');

      done();
    });
  });

  it(`shows a "minimum seach query" message if showMinimumSearchQueryMessage === true`, done => {
    wrapper.setProps({ showMinimumSearchQueryMessage: true });

    vm.$nextTick(() => {
      const minimumSearchEl = vm.$el.querySelector('.js-minimum-search-query-message');

      expect(minimumSearchEl).toBeTruthy();

      expect(trimText(minimumSearchEl.textContent)).toEqual(
        'Enter at least three characters to search',
      );

      done();
    });
  });

  it(`shows a error message if showSearchErrorMessage === true`, done => {
    wrapper.setProps({ showSearchErrorMessage: true });

    vm.$nextTick(() => {
      const errorMessageEl = vm.$el.querySelector('.js-search-error-message');

      expect(errorMessageEl).toBeTruthy();

      expect(trimText(errorMessageEl.textContent)).toEqual(
        'Something went wrong, unable to search projects',
      );

      done();
    });
  });

  it(`focuses the input element when the focusSearchInput() method is called`, () => {
    const input = vm.$el.querySelector('.js-project-selector-input');

    expect(document.activeElement).not.toBe(input);
    vm.focusSearchInput();

    expect(document.activeElement).toBe(input);
  });
});
