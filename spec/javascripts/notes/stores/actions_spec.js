import Vue from 'vue';
import $ from 'jquery';
import _ from 'underscore';
import { TEST_HOST } from 'spec/test_constants';
import { headersInterceptor } from 'spec/helpers/vue_resource_helper';
import actionsModule, * as actions from '~/notes/stores/actions';
import * as mutationTypes from '~/notes/stores/mutation_types';
import * as notesConstants from '~/notes/constants';
import createStore from '~/notes/stores';
import mrWidgetEventHub from '~/vue_merge_request_widget/event_hub';
import service from '~/notes/services/notes_service';
import testAction from '../../helpers/vuex_action_helper';
import { resetStore } from '../helpers';
import {
  discussionMock,
  notesDataMock,
  userDataMock,
  noteableDataMock,
  individualNote,
} from '../mock_data';

const TEST_ERROR_MESSAGE = 'Test error message';

describe('Actions Notes Store', () => {
  let commit;
  let dispatch;
  let state;
  let store;
  let flashSpy;

  beforeEach(() => {
    store = createStore();
    commit = jasmine.createSpy('commit');
    dispatch = jasmine.createSpy('dispatch');
    state = {};
    flashSpy = spyOnDependency(actionsModule, 'Flash');
  });

  afterEach(() => {
    resetStore(store);
  });

  describe('setNotesData', () => {
    it('should set received notes data', done => {
      testAction(
        actions.setNotesData,
        notesDataMock,
        { notesData: {} },
        [{ type: 'SET_NOTES_DATA', payload: notesDataMock }],
        [],
        done,
      );
    });
  });

  describe('setNoteableData', () => {
    it('should set received issue data', done => {
      testAction(
        actions.setNoteableData,
        noteableDataMock,
        { noteableData: {} },
        [{ type: 'SET_NOTEABLE_DATA', payload: noteableDataMock }],
        [],
        done,
      );
    });
  });

  describe('setUserData', () => {
    it('should set received user data', done => {
      testAction(
        actions.setUserData,
        userDataMock,
        { userData: {} },
        [{ type: 'SET_USER_DATA', payload: userDataMock }],
        [],
        done,
      );
    });
  });

  describe('setLastFetchedAt', () => {
    it('should set received timestamp', done => {
      testAction(
        actions.setLastFetchedAt,
        'timestamp',
        { lastFetchedAt: {} },
        [{ type: 'SET_LAST_FETCHED_AT', payload: 'timestamp' }],
        [],
        done,
      );
    });
  });

  describe('setInitialNotes', () => {
    it('should set initial notes', done => {
      testAction(
        actions.setInitialNotes,
        [individualNote],
        { notes: [] },
        [{ type: 'SET_INITIAL_DISCUSSIONS', payload: [individualNote] }],
        [],
        done,
      );
    });
  });

  describe('setTargetNoteHash', () => {
    it('should set target note hash', done => {
      testAction(
        actions.setTargetNoteHash,
        'hash',
        { notes: [] },
        [{ type: 'SET_TARGET_NOTE_HASH', payload: 'hash' }],
        [],
        done,
      );
    });
  });

  describe('toggleDiscussion', () => {
    it('should toggle discussion', done => {
      testAction(
        actions.toggleDiscussion,
        { discussionId: discussionMock.id },
        { notes: [discussionMock] },
        [{ type: 'TOGGLE_DISCUSSION', payload: { discussionId: discussionMock.id } }],
        [],
        done,
      );
    });
  });

  describe('expandDiscussion', () => {
    it('should expand discussion', done => {
      testAction(
        actions.expandDiscussion,
        { discussionId: discussionMock.id },
        { notes: [discussionMock] },
        [{ type: 'EXPAND_DISCUSSION', payload: { discussionId: discussionMock.id } }],
        [{ type: 'diffs/renderFileForDiscussionId', payload: discussionMock.id }],
        done,
      );
    });
  });

  describe('collapseDiscussion', () => {
    it('should commit collapse discussion', done => {
      testAction(
        actions.collapseDiscussion,
        { discussionId: discussionMock.id },
        { notes: [discussionMock] },
        [{ type: 'COLLAPSE_DISCUSSION', payload: { discussionId: discussionMock.id } }],
        [],
        done,
      );
    });
  });

  describe('async methods', () => {
    const interceptor = (request, next) => {
      next(
        request.respondWith(JSON.stringify({}), {
          status: 200,
        }),
      );
    };

    beforeEach(() => {
      Vue.http.interceptors.push(interceptor);
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
    });

    describe('closeIssue', () => {
      it('sets state as closed', done => {
        store
          .dispatch('closeIssue', { notesData: { closeIssuePath: '' } })
          .then(() => {
            expect(store.state.noteableData.state).toEqual('closed');
            expect(store.state.isToggleStateButtonLoading).toEqual(false);
            done();
          })
          .catch(done.fail);
      });
    });

    describe('reopenIssue', () => {
      it('sets state as reopened', done => {
        store
          .dispatch('reopenIssue', { notesData: { reopenIssuePath: '' } })
          .then(() => {
            expect(store.state.noteableData.state).toEqual('reopened');
            expect(store.state.isToggleStateButtonLoading).toEqual(false);
            done();
          })
          .catch(done.fail);
      });
    });
  });

  describe('emitStateChangedEvent', () => {
    it('emits an event on the document', () => {
      document.addEventListener('issuable_vue_app:change', event => {
        expect(event.detail.data).toEqual({ id: '1', state: 'closed' });
        expect(event.detail.isClosed).toEqual(false);
      });

      store.dispatch('emitStateChangedEvent', { id: '1', state: 'closed' });
    });
  });

  describe('toggleStateButtonLoading', () => {
    it('should set loading as true', done => {
      testAction(
        actions.toggleStateButtonLoading,
        true,
        {},
        [{ type: 'TOGGLE_STATE_BUTTON_LOADING', payload: true }],
        [],
        done,
      );
    });

    it('should set loading as false', done => {
      testAction(
        actions.toggleStateButtonLoading,
        false,
        {},
        [{ type: 'TOGGLE_STATE_BUTTON_LOADING', payload: false }],
        [],
        done,
      );
    });
  });

  describe('toggleIssueLocalState', () => {
    it('sets issue state as closed', done => {
      testAction(actions.toggleIssueLocalState, 'closed', {}, [{ type: 'CLOSE_ISSUE' }], [], done);
    });

    it('sets issue state as reopened', done => {
      testAction(
        actions.toggleIssueLocalState,
        'reopened',
        {},
        [{ type: 'REOPEN_ISSUE' }],
        [],
        done,
      );
    });
  });

  describe('poll', () => {
    beforeEach(done => {
      jasmine.clock().install();

      spyOn(Vue.http, 'get').and.callThrough();

      store
        .dispatch('setNotesData', notesDataMock)
        .then(done)
        .catch(done.fail);
    });

    afterEach(() => {
      jasmine.clock().uninstall();
    });

    it('calls service with last fetched state', done => {
      const interceptor = (request, next) => {
        next(
          request.respondWith(
            JSON.stringify({
              notes: [],
              last_fetched_at: '123456',
            }),
            {
              status: 200,
              headers: {
                'poll-interval': '1000',
              },
            },
          ),
        );
      };

      Vue.http.interceptors.push(interceptor);
      Vue.http.interceptors.push(headersInterceptor);

      store
        .dispatch('poll')
        .then(() => new Promise(resolve => requestAnimationFrame(resolve)))
        .then(() => {
          expect(Vue.http.get).toHaveBeenCalled();
          expect(store.state.lastFetchedAt).toBe('123456');

          jasmine.clock().tick(1500);
        })
        .then(
          () =>
            new Promise(resolve => {
              requestAnimationFrame(resolve);
            }),
        )
        .then(() => {
          expect(Vue.http.get.calls.count()).toBe(2);
          expect(Vue.http.get.calls.mostRecent().args[1].headers).toEqual({
            'X-Last-Fetched-At': '123456',
          });
        })
        .then(() => store.dispatch('stopPolling'))
        .then(() => {
          Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
          Vue.http.interceptors = _.without(Vue.http.interceptors, headersInterceptor);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('setNotesFetchedState', () => {
    it('should set notes fetched state', done => {
      testAction(
        actions.setNotesFetchedState,
        true,
        {},
        [{ type: 'SET_NOTES_FETCHED_STATE', payload: true }],
        [],
        done,
      );
    });
  });

  describe('deleteNote', () => {
    const interceptor = (request, next) => {
      next(
        request.respondWith(JSON.stringify({}), {
          status: 200,
        }),
      );
    };

    beforeEach(() => {
      Vue.http.interceptors.push(interceptor);

      $('body').attr('data-page', '');
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);

      $('body').attr('data-page', '');
    });

    it('commits DELETE_NOTE and dispatches updateMergeRequestWidget', done => {
      const note = { path: `${gl.TEST_HOST}`, id: 1 };

      testAction(
        actions.deleteNote,
        note,
        store.state,
        [
          {
            type: 'DELETE_NOTE',
            payload: note,
          },
        ],
        [
          {
            type: 'updateMergeRequestWidget',
          },
          {
            type: 'updateResolvableDiscussionsCounts',
          },
        ],
        done,
      );
    });

    it('dispatches removeDiscussionsFromDiff on merge request page', done => {
      const note = { path: `${gl.TEST_HOST}`, id: 1 };

      $('body').attr('data-page', 'projects:merge_requests:show');

      testAction(
        actions.deleteNote,
        note,
        store.state,
        [
          {
            type: 'DELETE_NOTE',
            payload: note,
          },
        ],
        [
          {
            type: 'updateMergeRequestWidget',
          },
          {
            type: 'updateResolvableDiscussionsCounts',
          },
          {
            type: 'diffs/removeDiscussionsFromDiff',
          },
        ],
        done,
      );
    });
  });

  describe('createNewNote', () => {
    describe('success', () => {
      const res = {
        id: 1,
        valid: true,
      };
      const interceptor = (request, next) => {
        next(
          request.respondWith(JSON.stringify(res), {
            status: 200,
          }),
        );
      };

      beforeEach(() => {
        Vue.http.interceptors.push(interceptor);
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
      });

      it('commits ADD_NEW_NOTE and dispatches updateMergeRequestWidget', done => {
        testAction(
          actions.createNewNote,
          { endpoint: `${gl.TEST_HOST}`, data: {} },
          store.state,
          [
            {
              type: 'ADD_NEW_NOTE',
              payload: res,
            },
          ],
          [
            {
              type: 'updateMergeRequestWidget',
            },
            {
              type: 'startTaskList',
            },
            {
              type: 'updateResolvableDiscussionsCounts',
            },
          ],
          done,
        );
      });
    });

    describe('error', () => {
      const res = {
        errors: ['error'],
      };
      const interceptor = (request, next) => {
        next(
          request.respondWith(JSON.stringify(res), {
            status: 200,
          }),
        );
      };

      beforeEach(() => {
        Vue.http.interceptors.push(interceptor);
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
      });

      it('does not commit ADD_NEW_NOTE or dispatch updateMergeRequestWidget', done => {
        testAction(
          actions.createNewNote,
          { endpoint: `${gl.TEST_HOST}`, data: {} },
          store.state,
          [],
          [],
          done,
        );
      });
    });
  });

  describe('toggleResolveNote', () => {
    const res = {
      resolved: true,
    };
    const interceptor = (request, next) => {
      next(
        request.respondWith(JSON.stringify(res), {
          status: 200,
        }),
      );
    };

    beforeEach(() => {
      Vue.http.interceptors.push(interceptor);
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
    });

    describe('as note', () => {
      it('commits UPDATE_NOTE and dispatches updateMergeRequestWidget', done => {
        testAction(
          actions.toggleResolveNote,
          { endpoint: `${gl.TEST_HOST}`, isResolved: true, discussion: false },
          store.state,
          [
            {
              type: 'UPDATE_NOTE',
              payload: res,
            },
          ],
          [
            {
              type: 'updateResolvableDiscussionsCounts',
            },
            {
              type: 'updateMergeRequestWidget',
            },
          ],
          done,
        );
      });
    });

    describe('as discussion', () => {
      it('commits UPDATE_DISCUSSION and dispatches updateMergeRequestWidget', done => {
        testAction(
          actions.toggleResolveNote,
          { endpoint: `${gl.TEST_HOST}`, isResolved: true, discussion: true },
          store.state,
          [
            {
              type: 'UPDATE_DISCUSSION',
              payload: res,
            },
          ],
          [
            {
              type: 'updateResolvableDiscussionsCounts',
            },
            {
              type: 'updateMergeRequestWidget',
            },
          ],
          done,
        );
      });
    });
  });

  describe('updateMergeRequestWidget', () => {
    it('calls mrWidget checkStatus', () => {
      spyOn(mrWidgetEventHub, '$emit');

      actions.updateMergeRequestWidget();

      expect(mrWidgetEventHub.$emit).toHaveBeenCalledWith('mr.discussion.updated');
    });
  });

  describe('setCommentsDisabled', () => {
    it('should set comments disabled state', done => {
      testAction(
        actions.setCommentsDisabled,
        true,
        null,
        [{ type: 'DISABLE_COMMENTS', payload: true }],
        [],
        done,
      );
    });
  });

  describe('updateResolvableDiscussionsCounts', () => {
    it('commits UPDATE_RESOLVABLE_DISCUSSIONS_COUNTS', done => {
      testAction(
        actions.updateResolvableDiscussionsCounts,
        null,
        {},
        [{ type: 'UPDATE_RESOLVABLE_DISCUSSIONS_COUNTS' }],
        [],
        done,
      );
    });
  });

  describe('convertToDiscussion', () => {
    it('commits CONVERT_TO_DISCUSSION with noteId', done => {
      const noteId = 'dummy-note-id';
      testAction(
        actions.convertToDiscussion,
        noteId,
        {},
        [{ type: 'CONVERT_TO_DISCUSSION', payload: noteId }],
        [],
        done,
      );
    });
  });

  describe('updateOrCreateNotes', () => {
    it('Updates existing note', () => {
      const note = { id: 1234 };
      const getters = { notesById: { 1234: note } };

      actions.updateOrCreateNotes({ commit, state, getters, dispatch }, [note]);

      expect(commit.calls.allArgs()).toEqual([[mutationTypes.UPDATE_NOTE, note]]);
    });

    it('Creates a new note if none exisits', () => {
      const note = { id: 1234 };
      const getters = { notesById: {} };
      actions.updateOrCreateNotes({ commit, state, getters, dispatch }, [note]);

      expect(commit.calls.allArgs()).toEqual([[mutationTypes.ADD_NEW_NOTE, note]]);
    });

    describe('Discussion notes', () => {
      let note;
      let getters;

      beforeEach(() => {
        note = { id: 1234 };
        getters = { notesById: {} };
      });

      it('Adds a reply to an existing discussion', () => {
        state = { discussions: [note] };
        const discussionNote = {
          ...note,
          type: notesConstants.DISCUSSION_NOTE,
          discussion_id: 1234,
        };

        actions.updateOrCreateNotes({ commit, state, getters, dispatch }, [discussionNote]);

        expect(commit.calls.allArgs()).toEqual([
          [mutationTypes.ADD_NEW_REPLY_TO_DISCUSSION, discussionNote],
        ]);
      });

      it('fetches discussions for diff notes', () => {
        state = { discussions: [], notesData: { discussionsPath: 'Hello world' } };
        const diffNote = { ...note, type: notesConstants.DIFF_NOTE, discussion_id: 1234 };

        actions.updateOrCreateNotes({ commit, state, getters, dispatch }, [diffNote]);

        expect(dispatch.calls.allArgs()).toEqual([
          ['fetchDiscussions', { path: state.notesData.discussionsPath }],
        ]);
      });

      it('Adds a new note', () => {
        state = { discussions: [] };
        const discussionNote = {
          ...note,
          type: notesConstants.DISCUSSION_NOTE,
          discussion_id: 1234,
        };

        actions.updateOrCreateNotes({ commit, state, getters, dispatch }, [discussionNote]);

        expect(commit.calls.allArgs()).toEqual([[mutationTypes.ADD_NEW_NOTE, discussionNote]]);
      });
    });
  });

  describe('replyToDiscussion', () => {
    let res = { discussion: { notes: [] } };
    const payload = { endpoint: TEST_HOST, data: {} };
    const interceptor = (request, next) => {
      next(
        request.respondWith(JSON.stringify(res), {
          status: 200,
        }),
      );
    };

    beforeEach(() => {
      Vue.http.interceptors.push(interceptor);
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
    });

    it('updates discussion if response contains disussion', done => {
      testAction(
        actions.replyToDiscussion,
        payload,
        {
          notesById: {},
        },
        [{ type: mutationTypes.UPDATE_DISCUSSION, payload: res.discussion }],
        [
          { type: 'updateMergeRequestWidget' },
          { type: 'startTaskList' },
          { type: 'updateResolvableDiscussionsCounts' },
        ],
        done,
      );
    });

    it('adds a reply to a discussion', done => {
      res = {};

      testAction(
        actions.replyToDiscussion,
        payload,
        {
          notesById: {},
        },
        [{ type: mutationTypes.ADD_NEW_REPLY_TO_DISCUSSION, payload: res }],
        [],
        done,
      );
    });
  });

  describe('removeConvertedDiscussion', () => {
    it('commits CONVERT_TO_DISCUSSION with noteId', done => {
      const noteId = 'dummy-id';
      testAction(
        actions.removeConvertedDiscussion,
        noteId,
        {},
        [{ type: 'REMOVE_CONVERTED_DISCUSSION', payload: noteId }],
        [],
        done,
      );
    });
  });

  describe('resolveDiscussion', () => {
    let getters;
    let discussionId;

    beforeEach(() => {
      discussionId = discussionMock.id;
      state.discussions = [discussionMock];
      getters = {
        isDiscussionResolved: () => false,
      };
    });

    it('when unresolved, dispatches action', done => {
      testAction(
        actions.resolveDiscussion,
        { discussionId },
        { ...state, ...getters },
        [],
        [
          {
            type: 'toggleResolveNote',
            payload: {
              endpoint: discussionMock.resolve_path,
              isResolved: false,
              discussion: true,
            },
          },
        ],
        done,
      );
    });

    it('when resolved, does nothing', done => {
      getters.isDiscussionResolved = id => id === discussionId;

      testAction(
        actions.resolveDiscussion,
        { discussionId },
        { ...state, ...getters },
        [],
        [],
        done,
      );
    });
  });

  describe('saveNote', () => {
    const payload = { endpoint: TEST_HOST, data: { 'note[note]': 'some text' } };

    describe('if response contains errors', () => {
      const res = { errors: { something: ['went wrong'] } };

      it('throws an error', done => {
        actions
          .saveNote(
            {
              commit() {},
              dispatch: () => Promise.resolve(res),
            },
            payload,
          )
          .then(() => done.fail('Expected error to be thrown!'))
          .catch(error => {
            expect(error.message).toBe('Failed to save comment!');
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('if response contains no errors', () => {
      const res = { valid: true };

      it('returns the response', done => {
        actions
          .saveNote(
            {
              commit() {},
              dispatch: () => Promise.resolve(res),
            },
            payload,
          )
          .then(data => {
            expect(data).toBe(res);
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('submitSuggestion', () => {
    const discussionId = 'discussion-id';
    const noteId = 'note-id';
    const suggestionId = 'suggestion-id';
    let flashContainer;

    beforeEach(() => {
      spyOn(service, 'applySuggestion');
      dispatch.and.returnValue(Promise.resolve());
      service.applySuggestion.and.returnValue(Promise.resolve());
      flashContainer = {};
    });

    const testSubmitSuggestion = (done, expectFn) => {
      actions
        .submitSuggestion(
          { commit, dispatch },
          { discussionId, noteId, suggestionId, flashContainer },
        )
        .then(expectFn)
        .then(done)
        .catch(done.fail);
    };

    it('when service success, commits and resolves discussion', done => {
      testSubmitSuggestion(done, () => {
        expect(commit.calls.allArgs()).toEqual([
          [mutationTypes.APPLY_SUGGESTION, { discussionId, noteId, suggestionId }],
        ]);

        expect(dispatch.calls.allArgs()).toEqual([['resolveDiscussion', { discussionId }]]);
        expect(flashSpy).not.toHaveBeenCalled();
      });
    });

    it('when service fails, flashes error message', done => {
      const response = { response: { data: { message: TEST_ERROR_MESSAGE } } };

      service.applySuggestion.and.returnValue(Promise.reject(response));

      testSubmitSuggestion(done, () => {
        expect(commit).not.toHaveBeenCalled();
        expect(dispatch).not.toHaveBeenCalled();
        expect(flashSpy).toHaveBeenCalledWith(`${TEST_ERROR_MESSAGE}.`, 'alert', flashContainer);
      });
    });

    it('when resolve discussion fails, fail gracefully', done => {
      dispatch.and.returnValue(Promise.reject());

      testSubmitSuggestion(done, () => {
        expect(flashSpy).not.toHaveBeenCalled();
      });
    });
  });
});
