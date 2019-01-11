import Vue from 'vue';
import createStore from '~/notes/stores';
import DiscussionFilter from '~/notes/components/discussion_filter.vue';
import { DISCUSSION_FILTERS_DEFAULT_VALUE } from '~/notes/constants';
import { mountComponentWithStore } from '../../helpers/vue_mount_component_helper';
import { discussionFiltersMock, discussionMock } from '../mock_data';

describe('DiscussionFilter component', () => {
  let vm;
  let store;
  let eventHub;

  const mountComponent = () => {
    store = createStore();

    const discussions = [
      {
        ...discussionMock,
        id: discussionMock.id,
        notes: [{ ...discussionMock.notes[0], resolvable: true, resolved: true }],
      },
    ];
    const Component = Vue.extend(DiscussionFilter);
    const selectedValue = DISCUSSION_FILTERS_DEFAULT_VALUE;
    const props = { filters: discussionFiltersMock, selectedValue };

    store.state.discussions = discussions;
    return mountComponentWithStore(Component, {
      el: null,
      store,
      props,
    });
  };

  beforeEach(() => {
    window.mrTabs = undefined;
    vm = mountComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders the all filters', () => {
    expect(vm.$el.querySelectorAll('.dropdown-menu li').length).toEqual(
      discussionFiltersMock.length,
    );
  });

  it('renders the default selected item', () => {
    expect(vm.$el.querySelector('#discussion-filter-dropdown').textContent.trim()).toEqual(
      discussionFiltersMock[0].title,
    );
  });

  it('updates to the selected item', () => {
    const filterItem = vm.$el.querySelector('.dropdown-menu li:last-child button');
    filterItem.click();

    expect(vm.currentFilter.title).toEqual(filterItem.textContent.trim());
  });

  it('only updates when selected filter changes', () => {
    const filterItem = vm.$el.querySelector('.dropdown-menu li:first-child button');

    spyOn(vm, 'filterDiscussion');
    filterItem.click();

    expect(vm.filterDiscussion).not.toHaveBeenCalled();
  });

  it('disables commenting when "Show history only" filter is applied', () => {
    const filterItem = vm.$el.querySelector('.dropdown-menu li:last-child button');
    filterItem.click();

    expect(vm.$store.state.commentsDisabled).toBe(true);
  });

  it('enables commenting when "Show history only" filter is not applied', () => {
    const filterItem = vm.$el.querySelector('.dropdown-menu li:first-child button');
    filterItem.click();

    expect(vm.$store.state.commentsDisabled).toBe(false);
  });

  it('renders a dropdown divider for the default filter', () => {
    const defaultFilter = vm.$el.querySelector('.dropdown-menu li:first-child');

    expect(defaultFilter.lastChild.classList).toContain('dropdown-divider');
  });

  describe('Merge request tabs', () => {
    eventHub = new Vue();

    beforeEach(() => {
      window.mrTabs = {
        eventHub,
        currentTab: 'show',
      };

      vm = mountComponent();
    });

    afterEach(() => {
      window.mrTabs = undefined;
    });

    it('only renders when discussion tab is active', done => {
      eventHub.$emit('MergeRequestTabChange', 'commit');

      vm.$nextTick(() => {
        expect(vm.$el.querySelector).toBeUndefined();
        done();
      });
    });
  });

  describe('URL with Links to notes', () => {
    afterEach(() => {
      window.location.hash = '';
    });

    it('updates the filter when the URL links to a note', done => {
      window.location.hash = `note_${discussionMock.notes[0].id}`;
      vm.currentValue = discussionFiltersMock[2].value;
      vm.handleLocationHash();

      vm.$nextTick(() => {
        expect(vm.currentValue).toEqual(DISCUSSION_FILTERS_DEFAULT_VALUE);
        done();
      });
    });

    it('does not update the filter when the current filter is "Show all activity"', done => {
      window.location.hash = `note_${discussionMock.notes[0].id}`;
      vm.handleLocationHash();

      vm.$nextTick(() => {
        expect(vm.currentValue).toEqual(DISCUSSION_FILTERS_DEFAULT_VALUE);
        done();
      });
    });

    it('only updates filter when the URL links to a note', done => {
      window.location.hash = `testing123`;
      vm.handleLocationHash();

      vm.$nextTick(() => {
        expect(vm.currentValue).toEqual(DISCUSSION_FILTERS_DEFAULT_VALUE);
        done();
      });
    });
  });
});
