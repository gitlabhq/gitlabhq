import Vue from 'vue';
import _ from 'underscore';
import * as actions from '~/notes/stores/actions';
import store from '~/notes/stores';
import testAction from '../../helpers/vuex_action_helper';
import { resetStore } from '../helpers';
import { discussionMock, notesDataMock, userDataMock, noteableDataMock, individualNote } from '../mock_data';

describe('Actions Notes Store', () => {
  afterEach(() => {
    resetStore(store);
  });

  describe('setNotesData', () => {
    it('should set received notes data', (done) => {
      testAction(actions.setNotesData, null, { notesData: {} }, [
        { type: 'SET_NOTES_DATA', payload: notesDataMock },
      ], done);
    });
  });

  describe('setNoteableData', () => {
    it('should set received issue data', (done) => {
      testAction(actions.setNoteableData, null, { noteableData: {} }, [
        { type: 'SET_NOTEABLE_DATA', payload: noteableDataMock },
      ], done);
    });
  });

  describe('setUserData', () => {
    it('should set received user data', (done) => {
      testAction(actions.setUserData, null, { userData: {} }, [
        { type: 'SET_USER_DATA', payload: userDataMock },
      ], done);
    });
  });

  describe('setLastFetchedAt', () => {
    it('should set received timestamp', (done) => {
      testAction(actions.setLastFetchedAt, null, { lastFetchedAt: {} }, [
        { type: 'SET_LAST_FETCHED_AT', payload: 'timestamp' },
      ], done);
    });
  });

  describe('setInitialNotes', () => {
    it('should set initial notes', (done) => {
      testAction(actions.setInitialNotes, null, { notes: [] }, [
        { type: 'SET_INITIAL_NOTES', payload: [individualNote] },
      ], done);
    });
  });

  describe('setTargetNoteHash', () => {
    it('should set target note hash', (done) => {
      testAction(actions.setTargetNoteHash, null, { notes: [] }, [
        { type: 'SET_TARGET_NOTE_HASH', payload: 'hash' },
      ], done);
    });
  });

  describe('toggleDiscussion', () => {
    it('should toggle discussion', (done) => {
      testAction(actions.toggleDiscussion, null, { notes: [discussionMock] }, [
        { type: 'TOGGLE_DISCUSSION', payload: { discussionId: discussionMock.id } },
      ], done);
    });
  });

  describe('async methods', () => {
    const interceptor = (request, next) => {
      next(request.respondWith(JSON.stringify({}), {
        status: 200,
      }));
    };

    beforeEach(() => {
      Vue.http.interceptors.push(interceptor);
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
    });

    describe('closeIssue', () => {
      it('sets state as closed', (done) => {
        store.dispatch('closeIssue', { notesData: { closeIssuePath: '' } })
          .then(() => {
            expect(store.state.noteableData.state).toEqual('closed');
            done();
          })
          .catch(done.fail);
      });
    });

    describe('reopenIssue', () => {
      it('sets state as reopened', (done) => {
        store.dispatch('reopenIssue', { notesData: { reopenIssuePath: '' } })
          .then(() => {
            expect(store.state.noteableData.state).toEqual('reopened');
            done();
          })
          .catch(done.fail);
      });
    });
  });

  describe('emitStateChangedEvent', () => {
    it('emits an event on the document', () => {
      document.addEventListener('issuable_vue_app:change', (event) => {
        expect(event.detail.data).toEqual({ id: '1', state: 'closed' });
        expect(event.detail.isClosed).toEqual(true);
      });

      store.dispatch('emitStateChangedEvent', { id: '1', state: 'closed' });
    });
  });

  describe('toggleIssueLocalState', () => {
    it('sets issue state as closed', (done) => {
      testAction(actions.toggleIssueLocalState, 'closed', {}, [
        { type: 'CLOSE_ISSUE', payload: 'closed' },
      ], done);
    });

    it('sets issue state as reopened', (done) => {
      testAction(actions.toggleIssueLocalState, 'reopened', {}, [
        { type: 'REOPEN_ISSUE', payload: 'reopened' },
      ], done);
    });
  });
});
