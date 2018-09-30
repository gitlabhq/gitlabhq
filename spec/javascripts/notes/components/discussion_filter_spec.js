import Vue from 'vue';
import createStore from '~/notes/stores';
import DiscussionFilter from '~/notes/components/discussion_filter.vue';
import eventHub from '~/notes/event_hub';
import { mountComponentWithStore } from '../../helpers/vue_mount_component_helper';
import { discussionFiltersMock, discussionMock } from '../mock_data';

describe('DiscussionFilter component', () => {
  let vm;
  let store;

  beforeEach(() => {
    setFixtures('<div id="js-vue-discussion-filter"></div>');

    store = createStore();

    const discussions = [{
      ...discussionMock,
      id: discussionMock.id,
      notes: [{ ...discussionMock.notes[0], resolvable: true, resolved: true }],
    }];
    const Component = Vue.extend(DiscussionFilter);
    const defaultValue = discussionFiltersMock[0].value;

    store.replaceState({
      ...store.state,
      discussions,
    });

    vm = mountComponentWithStore(Component, {
      el: '#js-vue-discussion-filter',
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

  it('only renders when at least one discussion is present', (done) => {
    store.state.discussions = [];

    Vue.nextTick()
      .then(() => {
        expect(vm.$el.childElementCount).toBeFalsy();
      })
      .then(done)
      .catch(done.fail);
  });

  it('only updates when selected changes', () => {
    const filterItem = vm.$el.querySelector('.dropdown-menu li:first-child button');

    spyOn(eventHub, '$emit');
    filterItem.click();

    expect(eventHub.$emit).not.toHaveBeenCalled();
  });
});
