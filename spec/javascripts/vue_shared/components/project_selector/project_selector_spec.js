import Vue from 'vue';
import _ from 'underscore';

import { GlSearchBoxByType, GlInfiniteScroll } from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import { trimText } from 'spec/helpers/text_helper';
import ProjectListItem from '~/vue_shared/components/project_selector/project_list_item.vue';
import ProjectSelector from '~/vue_shared/components/project_selector/project_selector.vue';

const localVue = createLocalVue();

describe('ProjectSelector component', () => {
  let wrapper;
  let vm;
  loadJSONFixtures('static/projects.json');
  const allProjects = getJSONFixture('static/projects.json');
  const searchResults = allProjects.slice(0, 5);
  let selected = [];
  selected = selected.concat(allProjects.slice(0, 3)).concat(allProjects.slice(5, 8));

  const findSearchInput = () => wrapper.find(GlSearchBoxByType).find('input');

  beforeEach(() => {
    jasmine.clock().install();

    wrapper = mount(Vue.extend(ProjectSelector), {
      localVue,
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
    const searchInput = findSearchInput();

    searchInput.setValue(query);
    searchInput.trigger('input');

    expect(vm.$emit).not.toHaveBeenCalledWith();
    jasmine.clock().tick(501);

    expect(vm.$emit).toHaveBeenCalledWith('searched', query);
  });

  it(`debounces the search input`, () => {
    spyOn(vm, '$emit');
    const searchInput = findSearchInput();

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
    const searchInput = findSearchInput();

    expect(searchInput.attributes('placeholder')).toBe('Search your projects');
  });

  it(`triggers a "bottomReached" event when user has scrolled to the bottom of the list`, () => {
    spyOn(vm, '$emit');
    wrapper.find(GlInfiniteScroll).vm.$emit('bottomReached');

    expect(vm.$emit).toHaveBeenCalledWith('bottomReached');
  });

  it(`triggers a "projectClicked" event when a project is clicked`, () => {
    spyOn(vm, '$emit');
    wrapper.find(ProjectListItem).vm.$emit('click', _.first(searchResults));

    expect(vm.$emit).toHaveBeenCalledWith('projectClicked', _.first(searchResults));
  });

  it(`shows a "no results" message if showNoResultsMessage === true`, () => {
    wrapper.setProps({ showNoResultsMessage: true });

    return vm.$nextTick().then(() => {
      const noResultsEl = wrapper.find('.js-no-results-message');

      expect(noResultsEl.exists()).toBe(true);
      expect(trimText(noResultsEl.text())).toEqual('Sorry, no projects matched your search');
    });
  });

  it(`shows a "minimum search query" message if showMinimumSearchQueryMessage === true`, () => {
    wrapper.setProps({ showMinimumSearchQueryMessage: true });

    return vm.$nextTick().then(() => {
      const minimumSearchEl = wrapper.find('.js-minimum-search-query-message');

      expect(minimumSearchEl.exists()).toBe(true);
      expect(trimText(minimumSearchEl.text())).toEqual('Enter at least three characters to search');
    });
  });

  it(`shows a error message if showSearchErrorMessage === true`, () => {
    wrapper.setProps({ showSearchErrorMessage: true });

    return vm.$nextTick().then(() => {
      const errorMessageEl = wrapper.find('.js-search-error-message');

      expect(errorMessageEl.exists()).toBe(true);
      expect(trimText(errorMessageEl.text())).toEqual(
        'Something went wrong, unable to search projects',
      );
    });
  });
});
