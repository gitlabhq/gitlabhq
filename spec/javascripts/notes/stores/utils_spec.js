import {
  whereDiscussionMatchesHash,
} from '~/notes/stores/utils';

const TEST_DISCUSSIONS = [
  {
    id: 'abc',
    notes: [],
    line_code: 'zzz123',
  },
  {
    id: 'def',
    notes: [
      { id: 1 },
      { id: 2 },
    ],
    line_code: 'zzz456',
  },
  {
    id: 'ghi',
    notes: [],
    line_code: null,
  },
  {
    id: 'jkl',
    notes: [
      { id: 3 },
      { id: 4 },
    ],
    line_code: null,
  },
  {
    id: 'mno',
    notes: [
      { id: 5 },
    ],
    line_code: 'zzz456',
  },
];

describe('notes/stores/utils', () => {
  describe('whereDiscussionMatchesHash', () => {
    it('returns filter for note id if hash is "note_*"', () => {
      const filter = whereDiscussionMatchesHash('note_4');

      const result = TEST_DISCUSSIONS.filter(filter);

      expect(result).toEqual([TEST_DISCUSSIONS[3]]);
    });

    it('returns filter for discussion id if hash is "discussion_*"', () => {
      const filter = whereDiscussionMatchesHash('discussion_ghi');

      const result = TEST_DISCUSSIONS.filter(filter);

      expect(result).toEqual([TEST_DISCUSSIONS[2]]);
    });

    it('return filter for line_code if hash is "*"', () => {
      const filter = whereDiscussionMatchesHash('zzz456');

      const result = TEST_DISCUSSIONS.filter(filter);

      expect(result).toEqual([TEST_DISCUSSIONS[1], TEST_DISCUSSIONS[4]]);
    });

    it('return false filter if hash in falsey', () => {
      const filter = whereDiscussionMatchesHash('');

      const result = TEST_DISCUSSIONS.filter(filter);

      expect(result).toEqual([]);
    });
  });
});
