import Vue from 'vue';
import createStore from '~/notes/stores';
import DiscussionFilter from '~/notes/components/discussion_filter.vue';
import { mountComponentWithStore } from '../../helpers/vue_mount_component_helper';
import { discussionFiltersMock, discussionMock } from '../mock_data';

describe('DiscussionFilter component', () => {
  let vm;
  let store;

  beforeEach(() => {
    store = createStore();

    const discussions = [
      {
        ...discussionMock,
        id: discussionMock.id,
        notes: [{ ...discussionMock.notes[0], resolvable: true, resolved: true }],
      },
    ];
    const Component = Vue.extend(DiscussionFilter);
    const defaultValue = discussionFiltersMock[0].value;

    store.state.discussions = discussions;
    vm = mountComponentWithStore(Component, {
      el: null,
      store,
      props: {
        filters: discussionFiltersMock,
        defaultValue,
      },
    });
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
});
