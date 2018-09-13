import Vue from 'vue';
import mutations from '~/notes/stores/mutations';
import {
  note,
  discussionMock,
  notesDataMock,
  userDataMock,
  noteableDataMock,
  individualNote,
} from '../mock_data';

describe('Notes Store mutations', () => {
  describe('ADD_NEW_NOTE', () => {
    let state;
    let noteData;

    beforeEach(() => {
      state = { discussions: [] };
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
        discussions: [noteData],
      });
      expect(state.discussions.length).toBe(1);
    });

    it('should not add the same note to the notes array', () => {
      mutations.ADD_NEW_NOTE(state, note);
      expect(state.discussions.length).toBe(1);
    });
  });

  describe('ADD_NEW_REPLY_TO_DISCUSSION', () => {
    it('should add a reply to a specific discussion', () => {
      const state = { discussions: [discussionMock] };
      const newReply = Object.assign({}, note, { discussion_id: discussionMock.id });
      mutations.ADD_NEW_REPLY_TO_DISCUSSION(state, newReply);

      expect(state.discussions[0].notes.length).toEqual(4);
    });
  });

  describe('DELETE_NOTE', () => {
    it('should delete a note ', () => {
      const state = { discussions: [discussionMock] };
      const toDelete = discussionMock.notes[0];
      const lengthBefore = discussionMock.notes.length;

      mutations.DELETE_NOTE(state, toDelete);

      expect(state.discussions[0].notes.length).toEqual(lengthBefore - 1);
    });
  });

  describe('EXPAND_DISCUSSION', () => {
    it('should expand a collapsed discussion', () => {
      const discussion = Object.assign({}, discussionMock, { expanded: false });

      const state = {
        discussions: [discussion],
      };

      mutations.EXPAND_DISCUSSION(state, { discussionId: discussion.id });

      expect(state.discussions[0].expanded).toEqual(true);
    });
  });

  describe('COLLAPSE_DISCUSSION', () => {
    it('should collpase an expanded discussion', () => {
      const discussion = Object.assign({}, discussionMock, { expanded: true });

      const state = {
        discussions: [discussion],
      };

      mutations.COLLAPSE_DISCUSSION(state, { discussionId: discussion.id });

      expect(state.discussions[0].expanded).toEqual(false);
    });
  });

  describe('REMOVE_PLACEHOLDER_NOTES', () => {
    it('should remove all placeholder notes in indivudal notes and discussion', () => {
      const placeholderNote = Object.assign({}, individualNote, { isPlaceholderNote: true });
      const state = { discussions: [placeholderNote] };
      mutations.REMOVE_PLACEHOLDER_NOTES(state);

      expect(state.discussions).toEqual([]);
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

  describe('SET_NOTEABLE_DATA', () => {
    it('should set the issue data', () => {
      const state = {
        noteableData: {},
      };

      mutations.SET_NOTEABLE_DATA(state, noteableDataMock);
      expect(state.noteableData).toEqual(noteableDataMock);
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

  describe('SET_INITIAL_DISCUSSIONS', () => {
    it('should set the initial notes received', () => {
      const state = {
        discussions: [],
      };
      const legacyNote = {
        id: 2,
        individual_note: true,
        notes: [
          {
            note: '1',
          },
          {
            note: '2',
          },
        ],
      };

      mutations.SET_INITIAL_DISCUSSIONS(state, [note, legacyNote]);
      expect(state.discussions[0].id).toEqual(note.id);
      expect(state.discussions[1].notes[0].note).toBe(legacyNote.notes[0].note);
      expect(state.discussions[2].notes[0].note).toBe(legacyNote.notes[1].note);
      expect(state.discussions.length).toEqual(3);
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
        discussions: [],
      };
      mutations.SHOW_PLACEHOLDER_NOTE(state, note);
      expect(state.discussions[0].isPlaceholderNote).toEqual(true);
    });
  });

  describe('TOGGLE_AWARD', () => {
    it('should add award if user has not reacted yet', () => {
      const state = {
        discussions: [note],
        userData: userDataMock,
      };

      const data = {
        note,
        awardName: 'cartwheel',
      };

      mutations.TOGGLE_AWARD(state, data);
      const lastIndex = state.discussions[0].award_emoji.length - 1;

      expect(state.discussions[0].award_emoji[lastIndex]).toEqual({
        name: 'cartwheel',
        user: { id: userDataMock.id, name: userDataMock.name, username: userDataMock.username },
      });
    });

    it('should remove award if user already reacted', () => {
      const state = {
        discussions: [note],
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
      expect(state.discussions[0].award_emoji.length).toEqual(2);
    });
  });

  describe('TOGGLE_DISCUSSION', () => {
    it('should open a closed discussion', () => {
      const discussion = Object.assign({}, discussionMock, { expanded: false });

      const state = {
        discussions: [discussion],
      };

      mutations.TOGGLE_DISCUSSION(state, { discussionId: discussion.id });

      expect(state.discussions[0].expanded).toEqual(true);
    });

    it('should close a opened discussion', () => {
      const state = {
        discussions: [discussionMock],
      };

      mutations.TOGGLE_DISCUSSION(state, { discussionId: discussionMock.id });

      expect(state.discussions[0].expanded).toEqual(false);
    });
  });

  describe('UPDATE_NOTE', () => {
    it('should update a note', () => {
      const state = {
        discussions: [individualNote],
      };

      const updated = Object.assign({}, individualNote.notes[0], { note: 'Foo' });

      mutations.UPDATE_NOTE(state, updated);

      expect(state.discussions[0].notes[0].note).toEqual('Foo');
    });
  });

  describe('CLOSE_ISSUE', () => {
    it('should set issue as closed', () => {
      const state = {
        discussions: [],
        targetNoteHash: null,
        lastFetchedAt: null,
        isToggleStateButtonLoading: false,
        notesData: {},
        userData: {},
        noteableData: {},
      };

      mutations.CLOSE_ISSUE(state);
      expect(state.noteableData.state).toEqual('closed');
    });
  });

  describe('REOPEN_ISSUE', () => {
    it('should set issue as closed', () => {
      const state = {
        discussions: [],
        targetNoteHash: null,
        lastFetchedAt: null,
        isToggleStateButtonLoading: false,
        notesData: {},
        userData: {},
        noteableData: {},
      };

      mutations.REOPEN_ISSUE(state);
      expect(state.noteableData.state).toEqual('reopened');
    });
  });

  describe('TOGGLE_STATE_BUTTON_LOADING', () => {
    it('should set isToggleStateButtonLoading as true', () => {
      const state = {
        discussions: [],
        targetNoteHash: null,
        lastFetchedAt: null,
        isToggleStateButtonLoading: false,
        notesData: {},
        userData: {},
        noteableData: {},
      };

      mutations.TOGGLE_STATE_BUTTON_LOADING(state, true);
      expect(state.isToggleStateButtonLoading).toEqual(true);
    });

    it('should set isToggleStateButtonLoading as false', () => {
      const state = {
        discussions: [],
        targetNoteHash: null,
        lastFetchedAt: null,
        isToggleStateButtonLoading: true,
        notesData: {},
        userData: {},
        noteableData: {},
      };

      mutations.TOGGLE_STATE_BUTTON_LOADING(state, false);
      expect(state.isToggleStateButtonLoading).toEqual(false);
    });
  });

  describe('SET_NOTES_FETCHED_STATE', () => {
    it('should set the given state', () => {
      const state = {
        isNotesFetched: false,
      };

      mutations.SET_NOTES_FETCHED_STATE(state, true);
      expect(state.isNotesFetched).toEqual(true);
    });
  });

  describe('SET_DISCUSSION_DIFF_LINES', () => {
    it('sets truncated_diff_lines', () => {
      const state = {
        discussions: [
          {
            id: 1,
          },
        ],
      };

      mutations.SET_DISCUSSION_DIFF_LINES(state, { discussionId: 1, diffLines: ['test'] });

      expect(state.discussions[0].truncated_diff_lines).toEqual(['test']);
    });

    it('keeps reactivity of discussion', () => {
      const state = {};
      Vue.set(state, 'discussions', [
        {
          id: 1,
          expanded: false,
        },
      ]);
      const discussion = state.discussions[0];

      mutations.SET_DISCUSSION_DIFF_LINES(state, { discussionId: 1, diffLines: ['test'] });

      discussion.expanded = true;

      expect(state.discussions[0].expanded).toBe(true);
    });
  });
});
