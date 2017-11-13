import mutations from '~/notes/stores/mutations';
import { note, discussionMock, notesDataMock, userDataMock, issueDataMock, individualNote } from '../mock_data';

describe('Mutation Notes Store', () => {
  describe('ADD_NEW_NOTE', () => {
    let state;
    let noteData;

    beforeEach(() => {
      state = { notes: [] };
      noteData = {
        expanded: true,
        id: note.discussion_id,
        individual_note: true,
        notes: [note],
        reply_id: note.discussion_id,
      };
      mutations.ADD_NEW_NOTE(state, note);
    });

    it('should add a new note to an array of notes', () => {
      expect(state).toEqual({
        notes: [noteData],
      });
      expect(state.notes.length).toBe(1);
    });

    it('should not add the same note to the notes array', () => {
      mutations.ADD_NEW_NOTE(state, note);
      expect(state.notes.length).toBe(1);
    });
  });

  describe('ADD_NEW_REPLY_TO_DISCUSSION', () => {
    it('should add a reply to a specific discussion', () => {
      const state = { notes: [discussionMock] };
      const newReply = Object.assign({}, note, { discussion_id: discussionMock.id });
      mutations.ADD_NEW_REPLY_TO_DISCUSSION(state, newReply);

      expect(state.notes[0].notes.length).toEqual(4);
    });
  });

  describe('DELETE_NOTE', () => {
    it('should delete a note ', () => {
      const state = { notes: [discussionMock] };
      const toDelete = discussionMock.notes[0];
      const lengthBefore = discussionMock.notes.length;

      mutations.DELETE_NOTE(state, toDelete);

      expect(state.notes[0].notes.length).toEqual(lengthBefore - 1);
    });
  });

  describe('REMOVE_PLACEHOLDER_NOTES', () => {
    it('should remove all placeholder notes in indivudal notes and discussion', () => {
      const placeholderNote = Object.assign({}, individualNote, { isPlaceholderNote: true });
      const state = { notes: [placeholderNote] };
      mutations.REMOVE_PLACEHOLDER_NOTES(state);

      expect(state.notes).toEqual([]);
    });
  });

  describe('SET_NOTES_DATA', () => {
    it('should set an object with notesData', () => {
      const state = {
        notesData: {},
      };

      mutations.SET_NOTES_DATA(state, notesDataMock);
      expect(state.notesData).toEqual(notesDataMock);
    });
  });

  describe('SET_ISSUE_DATA', () => {
    it('should set the issue data', () => {
      const state = {
        issueData: {},
      };

      mutations.SET_ISSUE_DATA(state, issueDataMock);
      expect(state.issueData).toEqual(issueDataMock);
    });
  });

  describe('SET_USER_DATA', () => {
    it('should set the user data', () => {
      const state = {
        userData: {},
      };

      mutations.SET_USER_DATA(state, userDataMock);
      expect(state.userData).toEqual(userDataMock);
    });
  });

  describe('SET_INITIAL_NOTES', () => {
    it('should set the initial notes received', () => {
      const state = {
        notes: [],
      };

      mutations.SET_INITIAL_NOTES(state, [note]);
      expect(state.notes).toEqual([note]);
    });
  });

  describe('SET_LAST_FETCHED_AT', () => {
    it('should set timestamp', () => {
      const state = {
        lastFetchedAt: [],
      };

      mutations.SET_LAST_FETCHED_AT(state, 'timestamp');
      expect(state.lastFetchedAt).toEqual('timestamp');
    });
  });

  describe('SET_TARGET_NOTE_HASH', () => {
    it('should set the note hash', () => {
      const state = {
        targetNoteHash: [],
      };

      mutations.SET_TARGET_NOTE_HASH(state, 'hash');
      expect(state.targetNoteHash).toEqual('hash');
    });
  });

  describe('SHOW_PLACEHOLDER_NOTE', () => {
    it('should set a placeholder note', () => {
      const state = {
        notes: [],
      };
      mutations.SHOW_PLACEHOLDER_NOTE(state, note);
      expect(state.notes[0].isPlaceholderNote).toEqual(true);
    });
  });

  describe('TOGGLE_AWARD', () => {
    it('should add award if user has not reacted yet', () => {
      const state = {
        notes: [note],
        userData: userDataMock,
      };

      const data = {
        note,
        awardName: 'cartwheel',
      };

      mutations.TOGGLE_AWARD(state, data);
      const lastIndex = state.notes[0].award_emoji.length - 1;

      expect(state.notes[0].award_emoji[lastIndex]).toEqual({
        name: 'cartwheel',
        user: { id: userDataMock.id, name: userDataMock.name, username: userDataMock.username },
      });
    });

    it('should remove award if user already reacted', () => {
      const state = {
        notes: [note],
        userData: {
          id: 1,
          name: 'Administrator',
          username: 'root',
        },
      };

      const data = {
        note,
        awardName: 'bath_tone3',
      };
      mutations.TOGGLE_AWARD(state, data);
      expect(state.notes[0].award_emoji.length).toEqual(2);
    });
  });

  describe('TOGGLE_DISCUSSION', () => {
    it('should open a closed discussion', () => {
      const discussion = Object.assign({}, discussionMock, { expanded: false });

      const state = {
        notes: [discussion],
      };

      mutations.TOGGLE_DISCUSSION(state, { discussionId: discussion.id });

      expect(state.notes[0].expanded).toEqual(true);
    });

    it('should close a opened discussion', () => {
      const state = {
        notes: [discussionMock],
      };

      mutations.TOGGLE_DISCUSSION(state, { discussionId: discussionMock.id });

      expect(state.notes[0].expanded).toEqual(false);
    });
  });

  describe('UPDATE_NOTE', () => {
    it('should update a note', () => {
      const state = {
        notes: [individualNote],
      };

      const updated = Object.assign({}, individualNote.notes[0], { note: 'Foo' });

      mutations.UPDATE_NOTE(state, updated);

      expect(state.notes[0].notes[0].note).toEqual('Foo');
    });
  });
});
