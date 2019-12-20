import Vue from 'vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import createStore from '~/notes/stores';
import DiscussionCounter from '~/notes/components/discussion_counter.vue';
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
        window.mrTabs.currentAction = 'show';

        spyOn(vm, 'expandDiscussion').and.stub();
        const discussions = [
          {
            ...discussionMock,
            id: discussionMock.id,
            notes: [{ ...discussionMock.notes[0], resolvable: true, resolved: true }],
            resolved: true,
          },
          {
            ...discussionMock,
            id: discussionMock.id + 1,
            notes: [{ ...discussionMock.notes[0], resolvable: true, resolved: false }],
            resolved: false,
          },
        ];
        const firstDiscussionId = discussionMock.id + 1;
        store.replaceState({
          ...store.state,
          discussions,
        });
        vm.jumpToFirstUnresolvedDiscussion();

        expect(vm.expandDiscussion).toHaveBeenCalledWith({ discussionId: firstDiscussionId });
      });

      it('jumps to first unresolved discussion from diff tab if all diff discussions are resolved', () => {
        window.mrTabs.currentAction = 'diff';
        spyOn(vm, 'switchToDiscussionsTabAndJumpTo').and.stub();

        const unresolvedId = discussionMock.id + 1;
        const discussions = [
          {
            ...discussionMock,
            id: discussionMock.id,
            diff_discussion: true,
            notes: [{ ...discussionMock.notes[0], resolvable: true, resolved: true }],
            resolved: true,
          },
          {
            ...discussionMock,
            id: unresolvedId,
            notes: [{ ...discussionMock.notes[0], resolvable: true, resolved: false }],
            resolved: false,
          },
        ];
        store.replaceState({
          ...store.state,
          discussions,
        });
        vm.jumpToFirstUnresolvedDiscussion();

        expect(vm.switchToDiscussionsTabAndJumpTo).toHaveBeenCalledWith(unresolvedId);
      });
    });
  });
});
