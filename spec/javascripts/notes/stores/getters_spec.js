import * as getters from '~/notes/stores/getters';
import {
  notesDataMock,
  userDataMock,
  noteableDataMock,
  individualNote,
  collapseNotesMock,
  discussion1,
  discussion2,
  discussion3,
  resolvedDiscussion1,
  unresolvableDiscussion,
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

  describe('showJumpToNextDiscussion', () => {
    it('should return true if there are 2 or more unresolved discussions', () => {
      const localGetters = {
        unresolvedDiscussionsIdsByDate: ['123', '456'],
        allResolvableDiscussions: [],
      };

      expect(getters.showJumpToNextDiscussion(state, localGetters)()).toBe(true);
    });

    it('should return false if there are 1 or less unresolved discussions', () => {
      const localGetters = {
        unresolvedDiscussionsIdsByDate: ['123'],
        allResolvableDiscussions: [],
      };

      expect(getters.showJumpToNextDiscussion(state, localGetters)()).toBe(false);
    });
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

  describe('allResolvableDiscussions', () => {
    it('should return only resolvable discussions in same order', () => {
      state.discussions = [
        discussion3,
        unresolvableDiscussion,
        discussion1,
        unresolvableDiscussion,
        discussion2,
      ];

      expect(getters.allResolvableDiscussions(state)).toEqual([
        discussion3,
        discussion1,
        discussion2,
      ]);
    });

    it('should return empty array if there are no resolvable discussions', () => {
      state.discussions = [unresolvableDiscussion, unresolvableDiscussion];

      expect(getters.allResolvableDiscussions(state)).toEqual([]);
    });
  });

  describe('unresolvedDiscussionsIdsByDiff', () => {
    it('should return all discussions IDs in diff order', () => {
      const localGetters = {
        allResolvableDiscussions: [discussion3, discussion1, discussion2],
      };

      expect(getters.unresolvedDiscussionsIdsByDiff(state, localGetters)).toEqual([
        'abc1',
        'abc2',
        'abc3',
      ]);
    });

    it('should return empty array if all discussions have been resolved', () => {
      const localGetters = {
        allResolvableDiscussions: [resolvedDiscussion1],
      };

      expect(getters.unresolvedDiscussionsIdsByDiff(state, localGetters)).toEqual([]);
    });
  });

  describe('unresolvedDiscussionsIdsByDate', () => {
    it('should return all discussions in date ascending order', () => {
      const localGetters = {
        allResolvableDiscussions: [discussion3, discussion1, discussion2],
      };

      expect(getters.unresolvedDiscussionsIdsByDate(state, localGetters)).toEqual([
        'abc2',
        'abc1',
        'abc3',
      ]);
    });

    it('should return empty array if all discussions have been resolved', () => {
      const localGetters = {
        allResolvableDiscussions: [resolvedDiscussion1],
      };

      expect(getters.unresolvedDiscussionsIdsByDate(state, localGetters)).toEqual([]);
    });
  });

  describe('unresolvedDiscussionsIdsOrdered', () => {
    const localGetters = {
      unresolvedDiscussionsIdsByDate: ['123', '456'],
      unresolvedDiscussionsIdsByDiff: ['abc', 'def'],
    };

    it('should return IDs ordered by diff when diffOrder param is true', () => {
      expect(getters.unresolvedDiscussionsIdsOrdered(state, localGetters)(true)).toEqual([
        'abc',
        'def',
      ]);
    });

    it('should return IDs ordered by date when diffOrder param is not true', () => {
      expect(getters.unresolvedDiscussionsIdsOrdered(state, localGetters)(false)).toEqual([
        '123',
        '456',
      ]);

      expect(getters.unresolvedDiscussionsIdsOrdered(state, localGetters)(undefined)).toEqual([
        '123',
        '456',
      ]);
    });
  });

  describe('isLastUnresolvedDiscussion', () => {
    const localGetters = {
      unresolvedDiscussionsIdsOrdered: () => ['123', '456', '789'],
    };

    it('should return true if the discussion id provided is the last', () => {
      expect(getters.isLastUnresolvedDiscussion(state, localGetters)('789')).toBe(true);
    });

    it('should return false if the discussion id provided is not the last', () => {
      expect(getters.isLastUnresolvedDiscussion(state, localGetters)('123')).toBe(false);
      expect(getters.isLastUnresolvedDiscussion(state, localGetters)('456')).toBe(false);
    });
  });

  describe('nextUnresolvedDiscussionId', () => {
    const localGetters = {
      unresolvedDiscussionsIdsOrdered: () => ['123', '456', '789'],
    };

    it('should return the ID of the discussion after the ID provided', () => {
      expect(getters.nextUnresolvedDiscussionId(state, localGetters)('123')).toBe('456');
      expect(getters.nextUnresolvedDiscussionId(state, localGetters)('456')).toBe('789');
      expect(getters.nextUnresolvedDiscussionId(state, localGetters)('789')).toBe('123');
    });
  });

  describe('previousUnresolvedDiscussionId', () => {
    describe('with unresolved discussions', () => {
      const localGetters = {
        unresolvedDiscussionsIdsOrdered: () => ['123', '456', '789'],
      };

      it('with bogus returns falsey', () => {
        expect(getters.previousUnresolvedDiscussionId(state, localGetters)('bogus')).toBe('456');
      });

      [
        { id: '123', expected: '789' },
        { id: '456', expected: '123' },
        { id: '789', expected: '456' },
      ].forEach(({ id, expected }) => {
        it(`with ${id}, returns previous value`, () => {
          expect(getters.previousUnresolvedDiscussionId(state, localGetters)(id)).toBe(expected);
        });
      });
    });

    describe('with 1 unresolved discussion', () => {
      const localGetters = {
        unresolvedDiscussionsIdsOrdered: () => ['123'],
      };

      it('with bogus returns id', () => {
        expect(getters.previousUnresolvedDiscussionId(state, localGetters)('bogus')).toBe('123');
      });

      it('with match, returns value', () => {
        expect(getters.previousUnresolvedDiscussionId(state, localGetters)('123')).toEqual('123');
      });
    });

    describe('with 0 unresolved discussions', () => {
      const localGetters = {
        unresolvedDiscussionsIdsOrdered: () => [],
      };

      it('returns undefined', () => {
        expect(
          getters.previousUnresolvedDiscussionId(state, localGetters)('bogus'),
        ).toBeUndefined();
      });
    });
  });

  describe('firstUnresolvedDiscussionId', () => {
    const localGetters = {
      unresolvedDiscussionsIdsByDate: ['123', '456'],
      unresolvedDiscussionsIdsByDiff: ['abc', 'def'],
    };

    it('should return the first discussion id by diff when diffOrder param is true', () => {
      expect(getters.firstUnresolvedDiscussionId(state, localGetters)(true)).toBe('abc');
    });

    it('should return the first discussion id by date when diffOrder param is not true', () => {
      expect(getters.firstUnresolvedDiscussionId(state, localGetters)(false)).toBe('123');
      expect(getters.firstUnresolvedDiscussionId(state, localGetters)(undefined)).toBe('123');
    });

    it('should be falsy if all discussions are resolved', () => {
      const localGettersFalsy = {
        unresolvedDiscussionsIdsByDiff: [],
        unresolvedDiscussionsIdsByDate: [],
      };

      expect(getters.firstUnresolvedDiscussionId(state, localGettersFalsy)(true)).toBeFalsy();
      expect(getters.firstUnresolvedDiscussionId(state, localGettersFalsy)(false)).toBeFalsy();
    });
  });

  describe('getDiscussion', () => {
    it('returns discussion by ID', () => {
      state.discussions.push({ id: '1' });

      expect(getters.getDiscussion(state)('1')).toEqual({ id: '1' });
    });
  });
});
