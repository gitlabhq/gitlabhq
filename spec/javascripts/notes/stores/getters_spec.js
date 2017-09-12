import * as getters from '~/notes/stores/getters';
import { notesDataMock, userDataMock, issueDataMock, individualNote } from '../mock_data';

describe('Getters Notes Store', () => {
  let state;
  beforeEach(() => {
    state = {
      notes: [individualNote],
      targetNoteHash: 'hash',
      lastFetchedAt: 'timestamp',

      notesData: notesDataMock,
      userData: userDataMock,
      issueData: issueDataMock,
    };
  });
  describe('notes', () => {
    it('should return all notes in the store', () => {
      expect(getters.notes(state)).toEqual([individualNote]);
    });
  });

  describe('targetNoteHash', () => {
    it('should return `targetNoteHash`', () => {
      expect(getters.targetNoteHash(state)).toEqual('hash');
    });
  });

  describe('getNotesData', () => {
    it('should return all data in `notesData`', () => {
      expect(getters.getNotesData(state)).toEqual(notesDataMock);
    });
  });

  describe('getIssueData', () => {
    it('should return all data in `issueData`', () => {
      expect(getters.getIssueData(state)).toEqual(issueDataMock);
    });
  });

  describe('getUserData', () => {
    it('should return all data in `userData`', () => {
      expect(getters.getUserData(state)).toEqual(userDataMock);
    });
  });

  describe('notesById', () => {
    it('should return the note for the given id', () => {
      expect(getters.notesById(state)).toEqual({ 1390: individualNote.notes[0] });
    });
  });

  describe('getCurrentUserLastNote', () => {
    it('should return the last note of the current user', () => {
      expect(getters.getCurrentUserLastNote(state)).toEqual(individualNote.notes[0]);
    });
  });
});
