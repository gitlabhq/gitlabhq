import { shallowMount, createLocalVue } from '@vue/test-utils';
import createStore from '~/notes/stores';
import noteableDiscussion from '~/notes/components/noteable_discussion.vue';
import ReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import ResolveWithIssueButton from '~/notes/components/discussion_resolve_with_issue_button.vue';
import NoteForm from '~/notes/components/note_form.vue';
import '~/behaviors/markdown/render_gfm';
import { noteableDataMock, discussionMock, notesDataMock } from '../mock_data';
import mockDiffFile from '../../diffs/mock_data/diff_file';

const discussionWithTwoUnresolvedNotes = 'merge_requests/resolved_diff_discussion.json';

describe('noteable_discussion component', () => {
  let store;
  let wrapper;

  preloadFixtures(discussionWithTwoUnresolvedNotes);

  beforeEach(() => {
    window.mrTabs = {};
    store = createStore();
    store.dispatch('setNoteableData', noteableDataMock);
    store.dispatch('setNotesData', notesDataMock);

    const localVue = createLocalVue();
    wrapper = shallowMount(noteableDiscussion, {
      store,
      propsData: { discussion: discussionMock },
      localVue,
      sync: false,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render user avatar', () => {
    const discussion = { ...discussionMock };
    discussion.diff_file = mockDiffFile;
    discussion.diff_discussion = true;

    wrapper.setProps({ discussion, renderDiffFile: true });

    expect(wrapper.find('.user-avatar-link').exists()).toBe(true);
  });

  it('should not render thread header for non diff threads', () => {
    expect(wrapper.find('.discussion-header').exists()).toBe(false);
  });

  it('should render thread header', done => {
    const discussion = { ...discussionMock };
    discussion.diff_file = mockDiffFile;
    discussion.diff_discussion = true;

    wrapper.setProps({ discussion });

    wrapper.vm
      .$nextTick()
      .then(() => {
        expect(wrapper.find('.discussion-header').exists()).toBe(true);
      })
      .then(done)
      .catch(done.fail);
  });

  describe('actions', () => {
    it('should toggle reply form', done => {
      const replyPlaceholder = wrapper.find(ReplyPlaceholder);

      wrapper.vm
        .$nextTick()
        .then(() => {
          expect(wrapper.vm.isReplying).toEqual(false);

          replyPlaceholder.vm.$emit('onClick');
        })
        .then(() => wrapper.vm.$nextTick())
        .then(() => {
          expect(wrapper.vm.isReplying).toEqual(true);

          const noteForm = wrapper.find(NoteForm);

          expect(noteForm.exists()).toBe(true);

          const noteFormProps = noteForm.props();

          expect(noteFormProps.discussion).toBe(discussionMock);
          expect(noteFormProps.isEditing).toBe(false);
          expect(noteFormProps.line).toBe(null);
          expect(noteFormProps.saveButtonTitle).toBe('Comment');
          expect(noteFormProps.autosaveKey).toBe(`Note/Issue/${discussionMock.id}/Reply`);
        })
        .then(done)
        .catch(done.fail);
    });

    it('does not render jump to thread button', () => {
      expect(wrapper.find('*[data-original-title="Jump to next unresolved thread"]').exists()).toBe(
        false,
      );
    });
  });

  describe('methods', () => {
    describe('jumpToNextDiscussion', () => {
      it('expands next unresolved thread', done => {
        const discussion2 = getJSONFixture(discussionWithTwoUnresolvedNotes)[0];
        discussion2.resolved = false;
        discussion2.active = true;
        discussion2.id = 'next'; // prepare this for being identified as next one (to be jumped to)
        store.dispatch('setInitialNotes', [discussionMock, discussion2]);
        window.mrTabs.currentAction = 'show';

        wrapper.vm
          .$nextTick()
          .then(() => {
            spyOn(wrapper.vm, 'expandDiscussion').and.stub();

            const nextDiscussionId = discussion2.id;

            setFixtures(`<div class="discussion" data-discussion-id="${nextDiscussionId}"></div>`);

            wrapper.vm.jumpToNextDiscussion();

            expect(wrapper.vm.expandDiscussion).toHaveBeenCalledWith({
              discussionId: nextDiscussionId,
            });
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('action text', () => {
    const commitId = 'razupaltuff';
    const truncatedCommitId = commitId.substr(0, 8);
    let commitElement;

    beforeEach(done => {
      store.state.diffs = {
        projectPath: 'something',
      };

      wrapper.setProps({
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
      });

      wrapper.vm
        .$nextTick()
        .then(() => {
          commitElement = wrapper.find('.commit-sha');
        })
        .then(done)
        .catch(done.fail);
    });

    describe('for commit threads', () => {
      it('should display a monospace started a thread on commit', () => {
        expect(wrapper.text()).toContain(`started a thread on commit ${truncatedCommitId}`);
        expect(commitElement.exists()).toBe(true);
        expect(commitElement.text()).toContain(truncatedCommitId);
      });
    });

    describe('for diff thread with a commit id', () => {
      it('should display started thread on commit header', done => {
        wrapper.vm.discussion.for_commit = false;

        wrapper.vm.$nextTick(() => {
          expect(wrapper.text()).toContain(`started a thread on commit ${truncatedCommitId}`);

          expect(commitElement).not.toBe(null);

          done();
        });
      });

      it('should display outdated change on commit header', done => {
        wrapper.vm.discussion.for_commit = false;
        wrapper.vm.discussion.active = false;

        wrapper.vm.$nextTick(() => {
          expect(wrapper.text()).toContain(
            `started a thread on an outdated change in commit ${truncatedCommitId}`,
          );

          expect(commitElement).not.toBe(null);

          done();
        });
      });
    });

    describe('for diff threads without a commit id', () => {
      it('should show started a thread on the diff text', done => {
        Object.assign(wrapper.vm.discussion, {
          for_commit: false,
          commit_id: null,
        });

        wrapper.vm.$nextTick(() => {
          expect(wrapper.text()).toContain('started a thread on the diff');

          done();
        });
      });

      it('should show thread on older version text', done => {
        Object.assign(wrapper.vm.discussion, {
          for_commit: false,
          commit_id: null,
          active: false,
        });

        wrapper.vm.$nextTick(() => {
          expect(wrapper.text()).toContain('started a thread on an old version of the diff');

          done();
        });
      });
    });
  });

  describe('for resolved thread', () => {
    beforeEach(() => {
      const discussion = getJSONFixture(discussionWithTwoUnresolvedNotes)[0];
      wrapper.setProps({ discussion });
    });

    it('does not display a button to resolve with issue', () => {
      const button = wrapper.find(ResolveWithIssueButton);

      expect(button.exists()).toBe(false);
    });
  });

  describe('for unresolved thread', () => {
    beforeEach(done => {
      const discussion = {
        ...getJSONFixture(discussionWithTwoUnresolvedNotes)[0],
        expanded: true,
      };
      discussion.notes = discussion.notes.map(note => ({
        ...note,
        resolved: false,
      }));

      wrapper.setProps({ discussion });
      wrapper.vm
        .$nextTick()
        .then(done)
        .catch(done.fail);
    });

    it('displays a button to resolve with issue', () => {
      const button = wrapper.find(ResolveWithIssueButton);

      expect(button.exists()).toBe(true);
    });
  });
});
