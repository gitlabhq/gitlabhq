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

    vm.$destroy();
    vm = new Component({
      store,
      propsData: { discussion },
    }).$mount();

    expect(vm.$el.querySelector('.discussion-header')).not.toBeNull();
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

  describe('methods', () => {
    describe('jumpToNextDiscussion', () => {
      it('expands next unresolved discussion', done => {
        const discussion2 = getJSONFixture(discussionWithTwoUnresolvedNotes)[0];
        discussion2.resolved = false;
        discussion2.active = true;
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

  describe('action text', () => {
    const commitId = 'razupaltuff';
    const truncatedCommitId = commitId.substr(0, 8);
    let commitElement;

    beforeEach(() => {
      vm.$destroy();

      store.state.diffs = {
        projectPath: 'something',
      };

      vm = new Component({
        propsData: {
          discussion: {
            ...discussionMock,
            for_commit: true,
            commit_id: commitId,
            diff_discussion: true,
            diff_file: {
              ...mockDiffFile,
            },
          },
          renderDiffFile: true,
        },
        store,
      }).$mount();

      commitElement = vm.$el.querySelector('.commit-sha');
    });

    describe('for commit discussions', () => {
      it('should display a monospace started a discussion on commit', () => {
        expect(vm.$el).toContainText(`started a discussion on commit ${truncatedCommitId}`);
        expect(commitElement).not.toBe(null);
        expect(commitElement).toHaveText(truncatedCommitId);
      });
    });

    describe('for diff discussion with a commit id', () => {
      it('should display started discussion on commit header', done => {
        vm.discussion.for_commit = false;

        vm.$nextTick(() => {
          expect(vm.$el).toContainText(`started a discussion on commit ${truncatedCommitId}`);
          expect(commitElement).not.toBe(null);

          done();
        });
      });

      it('should display outdated change on commit header', done => {
        vm.discussion.for_commit = false;
        vm.discussion.active = false;

        vm.$nextTick(() => {
          expect(vm.$el).toContainText(
            `started a discussion on an outdated change in commit ${truncatedCommitId}`,
          );

          expect(commitElement).not.toBe(null);

          done();
        });
      });
    });

    describe('for diff discussions without a commit id', () => {
      it('should show started a discussion on the diff text', done => {
        Object.assign(vm.discussion, {
          for_commit: false,
          commit_id: null,
        });

        vm.$nextTick(() => {
          expect(vm.$el).toContainText('started a discussion on the diff');

          done();
        });
      });

      it('should show discussion on older version text', done => {
        Object.assign(vm.discussion, {
          for_commit: false,
          commit_id: null,
          active: false,
        });

        vm.$nextTick(() => {
          expect(vm.$el).toContainText('started a discussion on an old version of the diff');

          done();
        });
      });
    });
  });
});
