import Vue from 'vue';
import createStore from '~/notes/stores';
import DiscussionCounter from '~/notes/components/discussion_counter.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { noteableDataMock, discussionMock, notesDataMock } from '../mock_data';

describe('DiscussionCounter component', () => {
  let store;
  let vm;

  beforeEach(() => {
    window.mrTabs = {};

    const Component = Vue.extend(DiscussionCounter);

    store = createStore();
    store.dispatch('setNoteableData', noteableDataMock);
    store.dispatch('setNotesData', notesDataMock);

    vm = createComponentWithStore(Component, store);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('methods', () => {
    describe('jumpToFirstUnresolvedDiscussion', () => {
      it('expands unresolved discussion', () => {
        spyOn(vm, 'expandDiscussion').and.stub();
        const discussions = [
          {
            ...discussionMock,
            id: discussionMock.id,
            notes: [{ ...discussionMock.notes[0], resolvable: true, resolved: true }],
          },
          {
            ...discussionMock,
            id: discussionMock.id + 1,
            notes: [{ ...discussionMock.notes[0], resolvable: true, resolved: false }],
          },
        ];
        const firstDiscussionId = discussionMock.id + 1;
        store.replaceState({
          ...store.state,
          discussions,
        });
        setFixtures(`
          <div data-discussion-id="${firstDiscussionId}"></div>
        `);

        vm.jumpToFirstUnresolvedDiscussion();

        expect(vm.expandDiscussion).toHaveBeenCalledWith({ discussionId: firstDiscussionId });
      });
    });
  });
});
