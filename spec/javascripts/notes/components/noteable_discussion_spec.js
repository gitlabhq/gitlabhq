import { mount, createLocalVue } from '@vue/test-utils';
import createStore from '~/notes/stores';
import noteableDiscussion from '~/notes/components/noteable_discussion.vue';
import ReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import ResolveWithIssueButton from '~/notes/components/discussion_resolve_with_issue_button.vue';
import NoteForm from '~/notes/components/note_form.vue';
import '~/behaviors/markdown/render_gfm';
import {
  noteableDataMock,
  discussionMock,
  notesDataMock,
  loggedOutnoteableData,
  userDataMock,
} from '../mock_data';
import mockDiffFile from '../../diffs/mock_data/diff_file';
import { trimText } from '../../helpers/text_helper';

const discussionWithTwoUnresolvedNotes = 'merge_requests/resolved_diff_discussion.json';

const localVue = createLocalVue();

describe('noteable_discussion component', () => {
  let store;
  let wrapper;
  let originalGon;

  preloadFixtures(discussionWithTwoUnresolvedNotes);

  beforeEach(() => {
    window.mrTabs = {};
    store = createStore();
    store.dispatch('setNoteableData', noteableDataMock);
    store.dispatch('setNotesData', notesDataMock);

    wrapper = mount(localVue.extend(noteableDiscussion), {
      store,
      propsData: { discussion: discussionMock },
      localVue,
      sync: false,
    });
  });

  afterEach(() => {
    wrapper.destroy();
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
        current_user: {
          ...note.current_user,
          can_resolve: true,
        },
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

  describe('signout widget', () => {
    beforeEach(() => {
      originalGon = Object.assign({}, window.gon);
      window.gon = window.gon || {};
    });

    afterEach(() => {
      wrapper.destroy();
      window.gon = originalGon;
    });

    describe('user is logged in', () => {
      beforeEach(() => {
        window.gon.current_user_id = userDataMock.id;
        store.dispatch('setUserData', userDataMock);

        wrapper = mount(localVue.extend(noteableDiscussion), {
          store,
          propsData: { discussion: discussionMock },
          localVue,
          sync: false,
        });
      });

      it('should not render signed out widget', () => {
        expect(Boolean(wrapper.vm.isLoggedIn)).toBe(true);
        expect(trimText(wrapper.text())).not.toContain('Please register or sign in to reply');
      });
    });

    describe('user is not logged in', () => {
      beforeEach(() => {
        window.gon.current_user_id = null;
        store.dispatch('setNoteableData', loggedOutnoteableData);
        store.dispatch('setNotesData', notesDataMock);

        wrapper = mount(localVue.extend(noteableDiscussion), {
          store,
          propsData: { discussion: discussionMock },
          localVue,
          sync: false,
        });
      });

      it('should render signed out widget', () => {
        expect(Boolean(wrapper.vm.isLoggedIn)).toBe(false);
        expect(trimText(wrapper.text())).toContain('Please register or sign in to reply');
      });
    });
  });
});
