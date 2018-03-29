import Vue from 'vue';
import _ from 'underscore';
import { headersInterceptor } from 'spec/helpers/vue_resource_helper';
import * as actions from '~/notes/stores/actions';
import store from '~/notes/stores';
import testAction from '../../helpers/vuex_action_helper';
import { resetStore } from '../helpers';
import {
  discussionMock,
  notesDataMock,
  userDataMock,
  noteableDataMock,
  individualNote,
} from '../mock_data';

describe('Actions Notes Store', () => {
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
        [{ type: 'SET_INITIAL_NOTES', payload: [individualNote] }],
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
        done,
      );
    });

    it('should set loading as false', done => {
      testAction(
        actions.toggleStateButtonLoading,
        false,
        {},
        [{ type: 'TOGGLE_STATE_BUTTON_LOADING', payload: false }],
        done,
      );
    });
  });

  describe('toggleIssueLocalState', () => {
    it('sets issue state as closed', done => {
      testAction(actions.toggleIssueLocalState, 'closed', {}, [{ type: 'CLOSE_ISSUE' }], done);
    });

    it('sets issue state as reopened', done => {
      testAction(actions.toggleIssueLocalState, 'reopened', {}, [{ type: 'REOPEN_ISSUE' }], done);
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
          expect(Vue.http.get).toHaveBeenCalledWith(jasmine.anything(), {
            url: jasmine.anything(),
            method: 'get',
            headers: {
              'X-Last-Fetched-At': undefined,
            },
          });
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
});
