
import * as actions from '~/notes/stores/actions';
import testAction from './helpers';
import { note, discussionMock, notesDataMock, userDataMock, issueDataMock, individualNote } from '../mock_data';
import service from '~/notes/services/issue_notes_service';

// use require syntax for inline loaders.
// with inject-loader, this returns a module factory
// that allows us to inject mocked dependencies.
// const actionsInjector = require('inject-loader!./actions');

// const actions = actionsInjector({
//   '../api/shop': {
//     getProducts (cb) {
//       setTimeout(() => {
//         cb([ /* mocked response */ ])
//       }, 100)
//     }
//   }
// });

fdescribe('Actions Notes Store', () => {
  describe('setNotesData', () => {
    it('should set received notes data', (done) => {
      testAction(actions.setNotesData, null, { notesData: {} }, [
        { type: 'SET_NOTES_DATA', payload: notesDataMock },
      ], done);
    });
  });

  describe('setIssueData', () => {
    it('should set received issue data', (done) => {
      testAction(actions.setIssueData, null, { issueData: {} }, [
        { type: 'SET_ISSUE_DATA', payload: issueDataMock },
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
        { type: 'SET_INITAL_NOTES', payload: [individualNote] },
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

  describe('fetchNotes', () => {
    it('should request notes', (done) => {
      spyOn(service, 'fetchNotes').and.returnValue(Promise.resolve({
        json() {
          return [individualNote];
        },
      }));
      testAction(actions.fetchNotes, null, { notes: [] }, [
        { type: 'TOGGLE_DISCUSSION', payload: [individualNote] },
      ], done);
    });
  });

  describe('deleteNote', () => {
    it('should delete note', () => {});
  });

  describe('updateNote', () => {
    it('should update note', () => {

    });
  });

  describe('replyToDiscussion', () => {
    it('should add a reply to a discussion', () => {

    });
  });

  describe('createNewNote', () => {
    it('should create a new note', () => {});
  });

  describe('saveNote', () => {
    it('should save the received note', () => {

    });
  });

  describe('poll', () => {
    it('should start polling the received endoint', () => {

    });
  });

  describe('toggleAward', () => {
    it('should toggle received award', () => {

    });
  });

  describe('toggleAwardRequest', () => {
    it('should make a request to toggle the award', () => {

    });
  });

  describe('scrollToNoteIfNeeded', () => {
    it('should call `scrollToElement` if note is not in viewport', () => {
    });

    it('should note call `scrollToElement` if note is in viewport', () => {
    });
  });
});
