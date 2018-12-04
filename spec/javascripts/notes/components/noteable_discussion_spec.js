import Vue from 'vue';
import createStore from '~/notes/stores';
import noteableDiscussion from '~/notes/components/noteable_discussion.vue';
import '~/behaviors/markdown/render_gfm';
import { noteableDataMock, discussionMock, notesDataMock } from '../mock_data';
import mockDiffFile from '../../diffs/mock_data/diff_file';

const discussionWithTwoUnresolvedNotes = 'merge_requests/resolved_diff_discussion.json';

describe('noteable_discussion component', () => {
  const Component = Vue.extend(noteableDiscussion);
  let store;
  let vm;

  preloadFixtures(discussionWithTwoUnresolvedNotes);

  beforeEach(() => {
    window.mrTabs = {};
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

  it('should not render discussion header for non diff discussions', () => {
    expect(vm.$el.querySelector('.discussion-header')).toBeNull();
  });

  it('should render discussion header', () => {
    const discussion = { ...discussionMock };
    discussion.diff_file = mockDiffFile;
    discussion.diff_discussion = true;
    const diffDiscussionVm = new Component({
      store,
      propsData: { discussion },
    }).$mount();

    expect(diffDiscussionVm.$el.querySelector('.discussion-header')).not.toBeNull();
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

<<<<<<< HEAD
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

    describe('isRepliesCollapsed', () => {
      it('should return false for diff discussions', done => {
        const diffDiscussion = getJSONFixture(diffDiscussionFixture)[0];
        vm.$store.dispatch('setInitialNotes', [diffDiscussion]);

        Vue.nextTick()
          .then(() => {
            expect(vm.isRepliesCollapsed).toEqual(false);
            expect(vm.$el.querySelector('.js-toggle-replies')).not.toBeNull();
            expect(vm.$el.querySelector('.discussion-reply-holder')).not.toBeNull();
          })
          .then(done)
          .catch(done.fail);
      });

      it('should return false if discussion does not have a reply', () => {
        const discussion = { ...discussionMock, resolved: true };
        discussion.notes = discussion.notes.slice(0, 1);
        const noRepliesVm = new Component({
          store,
          propsData: { discussion },
        }).$mount();

        expect(noRepliesVm.isRepliesCollapsed).toEqual(false);
        expect(noRepliesVm.$el.querySelector('.js-toggle-replies')).toBeNull();
        expect(vm.$el.querySelector('.discussion-reply-holder')).not.toBeNull();
        noRepliesVm.$destroy();
      });

      it('should return true for resolved non-diff discussion which has replies', () => {
        const discussion = { ...discussionMock, resolved: true };
        const resolvedDiscussionVm = new Component({
          store,
          propsData: { discussion },
        }).$mount();

        expect(resolvedDiscussionVm.isRepliesCollapsed).toEqual(true);
        expect(resolvedDiscussionVm.$el.querySelector('.js-toggle-replies')).not.toBeNull();
        expect(vm.$el.querySelector('.discussion-reply-holder')).not.toBeNull();
        resolvedDiscussionVm.$destroy();
      });
    });
  });

=======
>>>>>>> 403430968cf... Merge branch 'winh-collapse-discussions' into 'master'
  describe('methods', () => {
    describe('jumpToNextDiscussion', () => {
      it('expands next unresolved discussion', done => {
        const discussion2 = getJSONFixture(discussionWithTwoUnresolvedNotes)[0];
        discussion2.resolved = false;
        discussion2.id = 'next'; // prepare this for being identified as next one (to be jumped to)
        vm.$store.dispatch('setInitialNotes', [discussionMock, discussion2]);
        window.mrTabs.currentAction = 'show';

        Vue.nextTick()
          .then(() => {
            spyOn(vm, 'expandDiscussion').and.stub();

            const nextDiscussionId = discussion2.id;

            setFixtures(`
              <div class="discussion" data-discussion-id="${nextDiscussionId}"></div>
            `);

            vm.jumpToNextDiscussion();

            expect(vm.expandDiscussion).toHaveBeenCalledWith({ discussionId: nextDiscussionId });
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('componentData', () => {
    it('should return first note object for placeholder note', () => {
      const data = {
        isPlaceholderNote: true,
        notes: [{ body: 'hello world!' }],
      };

      const note = vm.componentData(data);

      expect(note).toEqual(data.notes[0]);
    });

    it('should return given note for nonplaceholder notes', () => {
      const data = {
        notes: [{ id: 12 }],
      };

      const note = vm.componentData(data);

      expect(note).toEqual(data);
    });
  });
});
