import * as getters from '~/notes/stores/getters';
import {
  notesDataMock,
  userDataMock,
  noteableDataMock,
  individualNote,
  collapseNotesMock,
} from '../mock_data';

const discussionWithTwoUnresolvedNotes = 'merge_requests/resolved_diff_discussion.json';

describe('Getters Notes Store', () => {
  let state;

  preloadFixtures(discussionWithTwoUnresolvedNotes);

  beforeEach(() => {
    state = {
      discussions: [individualNote],
      targetNoteHash: 'hash',
      lastFetchedAt: 'timestamp',
      isNotesFetched: false,

      notesData: notesDataMock,
      userData: userDataMock,
      noteableData: noteableDataMock,
    };
  });

  describe('discussions', () => {
    it('should return all discussions in the store', () => {
      expect(getters.discussions(state)).toEqual([individualNote]);
    });
  });

  describe('resolvedDiscussionsById', () => {
    it('ignores unresolved system notes', () => {
      const [discussion] = getJSONFixture(discussionWithTwoUnresolvedNotes);
      discussion.notes[0].resolved = true;
      discussion.notes[1].resolved = false;
      state.discussions.push(discussion);

      expect(getters.resolvedDiscussionsById(state)).toEqual({
        [discussion.id]: discussion,
      });
    });
  });

  describe('Collapsed notes', () => {
    const stateCollapsedNotes = {
      discussions: collapseNotesMock,
      targetNoteHash: 'hash',
      lastFetchedAt: 'timestamp',

      notesData: notesDataMock,
      userData: userDataMock,
      noteableData: noteableDataMock,
    };

    it('should return a single system note when a description was updated multiple times', () => {
      expect(getters.discussions(stateCollapsedNotes).length).toEqual(1);
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

  describe('getNoteableData', () => {
    it('should return all data in `noteableData`', () => {
      expect(getters.getNoteableData(state)).toEqual(noteableDataMock);
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

  describe('openState', () => {
    it('should return the issue state', () => {
      expect(getters.openState(state)).toEqual(noteableDataMock.state);
    });
  });

  describe('isNotesFetched', () => {
    it('should return the state for the fetching notes', () => {
      expect(getters.isNotesFetched(state)).toBeFalsy();
    });
  });
});
