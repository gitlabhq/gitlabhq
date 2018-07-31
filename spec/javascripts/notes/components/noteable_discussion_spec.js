import Vue from 'vue';
import createStore from '~/notes/stores';
import noteableDiscussion from '~/notes/components/noteable_discussion.vue';
import '~/behaviors/markdown/render_gfm';
import { noteableDataMock, discussionMock, notesDataMock } from '../mock_data';

const discussionWithTwoUnresolvedNotes = 'merge_requests/resolved_diff_discussion.json';

describe('noteable_discussion component', () => {
  const Component = Vue.extend(noteableDiscussion);
  let store;
  let vm;

  preloadFixtures(discussionWithTwoUnresolvedNotes);

  beforeEach(() => {
    store = createStore();
    store.dispatch('setNoteableData', noteableDataMock);
    store.dispatch('setNotesData', notesDataMock);

    vm = new Component({
      store,
      propsData: { discussion: discussionMock },
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render user avatar', () => {
    expect(vm.$el.querySelector('.user-avatar-link')).not.toBeNull();
  });

  it('should render discussion header', () => {
    expect(vm.$el.querySelector('.discussion-header')).not.toBeNull();
    expect(vm.$el.querySelector('.notes').children.length).toEqual(discussionMock.notes.length);
  });

  describe('actions', () => {
    it('should render reply button', () => {
      expect(vm.$el.querySelector('.js-vue-discussion-reply').textContent.trim()).toEqual(
        'Reply...',
      );
    });

    it('should toggle reply form', done => {
      vm.$el.querySelector('.js-vue-discussion-reply').click();

      Vue.nextTick(() => {
        expect(vm.isReplying).toEqual(true);

        // There is a watcher for `isReplying` which will init autosave in the next tick
        Vue.nextTick(() => {
          expect(vm.$refs.noteForm).not.toBeNull();
          done();
        });
      });
    });

    it('does not render jump to discussion button', () => {
      expect(
        vm.$el.querySelector('*[data-original-title="Jump to next unresolved discussion"]'),
      ).toBeNull();
    });
  });

  describe('computed', () => {
    describe('hasMultipleUnresolvedDiscussions', () => {
      it('is false if there are no unresolved discussions', done => {
        spyOnProperty(vm, 'unresolvedDiscussions').and.returnValue([]);

        Vue.nextTick()
          .then(() => {
            expect(vm.hasMultipleUnresolvedDiscussions).toBe(false);
          })
          .then(done)
          .catch(done.fail);
      });

      it('is false if there is one unresolved discussion', done => {
        spyOnProperty(vm, 'unresolvedDiscussions').and.returnValue([discussionMock]);

        Vue.nextTick()
          .then(() => {
            expect(vm.hasMultipleUnresolvedDiscussions).toBe(false);
          })
          .then(done)
          .catch(done.fail);
      });

      it('is true if there are two unresolved discussions', done => {
        const discussion = getJSONFixture(discussionWithTwoUnresolvedNotes)[0];
        discussion.notes[0].resolved = false;
        vm.$store.dispatch('setInitialNotes', [discussion, discussion]);

        Vue.nextTick()
          .then(() => {
            expect(vm.hasMultipleUnresolvedDiscussions).toBe(true);
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('methods', () => {
    describe('jumpToNextDiscussion', () => {
      it('expands next unresolved discussion', () => {
        spyOn(vm, 'expandDiscussion').and.stub();
        const discussions = [
          discussionMock,
          {
            ...discussionMock,
            id: discussionMock.id + 1,
            notes: [{ ...discussionMock.notes[0], resolvable: true, resolved: true }],
          },
          {
            ...discussionMock,
            id: discussionMock.id + 2,
            notes: [{ ...discussionMock.notes[0], resolvable: true, resolved: false }],
          },
        ];
        const nextDiscussionId = discussionMock.id + 2;
        store.replaceState({
          ...store.state,
          discussions,
        });
        setFixtures(`
          <div data-discussion-id="${nextDiscussionId}"></div>
        `);

        vm.jumpToNextDiscussion();

        expect(vm.expandDiscussion).toHaveBeenCalledWith({ discussionId: nextDiscussionId });
      });
    });
  });
});
