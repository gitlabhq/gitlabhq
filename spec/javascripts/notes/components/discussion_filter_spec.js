import Vue from 'vue';
import DiscussionFilter from '~/notes/components/discussion_filter.vue';
import eventHub from '~/notes/event_hub';
import mountComponent from '../../helpers/vue_mount_component_helper';
import { discussionFiltersMock } from '../mock_data';

describe('DiscussionFilter component', () => {
  let vm;

  beforeEach(() => {

    const Component = Vue.extend(DiscussionFilter);
    const defaultValue = discussionFiltersMock[0].value;

    vm = mountComponent(Component, {
      filters: discussionFiltersMock,
      defaultValue,
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders the all filters', () => {
    expect(vm.$el.querySelectorAll('.dropdown-menu li').length).toEqual(discussionFiltersMock.length);
  });

  it('renders the default selected item', () => {
    expect(vm.$el.querySelector('#discussion-filter-dropdown').textContent.trim()).toEqual(discussionFiltersMock[0].title);
  });

  it('updates to the selected item', () => {
    const filterItem = vm.$el.querySelector('.dropdown-menu li:last-child button');

    spyOn(eventHub, '$emit');
    filterItem.click();

    expect(eventHub.$emit).toHaveBeenCalledWith('notes.filter', vm.currentValue);
    expect(vm.currentFilter.title).toEqual(filterItem.textContent.trim());
  });
});
