import * as actions from '~/notes/stores/actions';
import testAction from './helpers';
import { discussionMock, notesDataMock, userDataMock, issueDataMock, individualNote } from '../mock_data';

describe('Actions Notes Store', () => {
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
});
