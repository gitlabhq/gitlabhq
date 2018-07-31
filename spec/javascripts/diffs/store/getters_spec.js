import * as getters from '~/diffs/store/getters';
import state from '~/diffs/store/modules/diff_state';
import { PARALLEL_DIFF_VIEW_TYPE, INLINE_DIFF_VIEW_TYPE } from '~/diffs/constants';
import discussion from '../mock_data/diff_discussions';
import diffFile from '../mock_data/diff_file';

describe('Diffs Module Getters', () => {
  let localState;
  let discussionMock;
  let discussionMock1;

  const diffFileMock = {
    fileHash: '9732849daca6ae818696d9575f5d1207d1a7f8bb',
  };

  beforeEach(() => {
    localState = state();
    discussionMock = Object.assign({}, discussion);
    discussionMock.diff_file.file_hash = diffFileMock.fileHash;

    discussionMock1 = Object.assign({}, discussion);
    discussionMock1.diff_file.file_hash = diffFileMock.fileHash;
  });

  describe('isParallelView', () => {
    it('should return true if view set to parallel view', () => {
      localState.diffViewType = PARALLEL_DIFF_VIEW_TYPE;

      expect(getters.isParallelView(localState)).toEqual(true);
    });

    it('should return false if view not to parallel view', () => {
      localState.diffViewType = INLINE_DIFF_VIEW_TYPE;

      expect(getters.isParallelView(localState)).toEqual(false);
    });
  });

  describe('isInlineView', () => {
    it('should return true if view set to inline view', () => {
      localState.diffViewType = INLINE_DIFF_VIEW_TYPE;

      expect(getters.isInlineView(localState)).toEqual(true);
    });

    it('should return false if view not to inline view', () => {
      localState.diffViewType = PARALLEL_DIFF_VIEW_TYPE;

      expect(getters.isInlineView(localState)).toEqual(false);
    });
  });

  describe('areAllFilesCollapsed', () => {
    it('returns true when all files are collapsed', () => {
      localState.diffFiles = [{ collapsed: true }, { collapsed: true }];
      expect(getters.areAllFilesCollapsed(localState)).toEqual(true);
    });

    it('returns false when at least one file is not collapsed', () => {
      localState.diffFiles = [{ collapsed: false }, { collapsed: true }];
      expect(getters.areAllFilesCollapsed(localState)).toEqual(false);
    });
  });

  describe('commitId', () => {
    it('returns commit id when is set', () => {
      const commitID = '800f7a91';
      localState.commit = {
        id: commitID,
      };

      expect(getters.commitId(localState)).toEqual(commitID);
    });

    it('returns null when no commit is set', () => {
      expect(getters.commitId(localState)).toEqual(null);
    });
  });

  describe('diffHasAllExpandedDiscussions', () => {
    it('returns true when all discussions are expanded', () => {
      expect(
        getters.diffHasAllExpandedDiscussions(localState, {
          getDiffFileDiscussions: () => [discussionMock, discussionMock],
        })(diffFileMock),
      ).toEqual(true);
    });

    it('returns false when there are no discussions', () => {
      expect(
        getters.diffHasAllExpandedDiscussions(localState, {
          getDiffFileDiscussions: () => [],
        })(diffFileMock),
      ).toEqual(false);
    });

    it('returns false when one discussions is collapsed', () => {
      discussionMock1.expanded = false;

      expect(
        getters.diffHasAllExpandedDiscussions(localState, {
          getDiffFileDiscussions: () => [discussionMock, discussionMock1],
        })(diffFileMock),
      ).toEqual(false);
    });
  });

  describe('diffHasAllCollpasedDiscussions', () => {
    it('returns true when all discussions are collapsed', () => {
      discussionMock.diff_file.file_hash = diffFileMock.fileHash;
      discussionMock.expanded = false;

      expect(
        getters.diffHasAllCollpasedDiscussions(localState, {
          getDiffFileDiscussions: () => [discussionMock],
        })(diffFileMock),
      ).toEqual(true);
    });

    it('returns false when there are no discussions', () => {
      expect(
        getters.diffHasAllCollpasedDiscussions(localState, {
          getDiffFileDiscussions: () => [],
        })(diffFileMock),
      ).toEqual(false);
    });

    it('returns false when one discussions is expanded', () => {
      discussionMock1.expanded = false;

      expect(
        getters.diffHasAllCollpasedDiscussions(localState, {
          getDiffFileDiscussions: () => [discussionMock, discussionMock1],
        })(diffFileMock),
      ).toEqual(false);
    });
  });

  describe('diffHasExpandedDiscussions', () => {
    it('returns true when one of the discussions is expanded', () => {
      discussionMock1.expanded = false;

      expect(
        getters.diffHasExpandedDiscussions(localState, {
          getDiffFileDiscussions: () => [discussionMock, discussionMock],
        })(diffFileMock),
      ).toEqual(true);
    });

    it('returns false when there are no discussions', () => {
      expect(
        getters.diffHasExpandedDiscussions(localState, { getDiffFileDiscussions: () => [] })(
          diffFileMock,
        ),
      ).toEqual(false);
    });

    it('returns false when no discussion is expanded', () => {
      discussionMock.expanded = false;
      discussionMock1.expanded = false;

      expect(
        getters.diffHasExpandedDiscussions(localState, {
          getDiffFileDiscussions: () => [discussionMock, discussionMock1],
        })(diffFileMock),
      ).toEqual(false);
    });
  });

  describe('diffHasDiscussions', () => {
    it('returns true when getDiffFileDiscussions returns discussions', () => {
      expect(
        getters.diffHasDiscussions(localState, {
          getDiffFileDiscussions: () => [discussionMock],
        })(diffFileMock),
      ).toEqual(true);
    });

    it('returns false when getDiffFileDiscussions returns no discussions', () => {
      expect(
        getters.diffHasDiscussions(localState, {
          getDiffFileDiscussions: () => [],
        })(diffFileMock),
      ).toEqual(false);
    });
  });

  describe('getDiffFileDiscussions', () => {
    it('returns an array with discussions when fileHash matches and the discussion belongs to a diff', () => {
      discussionMock.diff_file.file_hash = diffFileMock.fileHash;

      expect(
        getters.getDiffFileDiscussions(localState, {}, {}, { discussions: [discussionMock] })(
          diffFileMock,
        ).length,
      ).toEqual(1);
    });

    it('returns an empty array when no discussions are found in the given diff', () => {
      expect(
        getters.getDiffFileDiscussions(localState, {}, {}, { discussions: [] })(diffFileMock)
          .length,
      ).toEqual(0);
    });
  });

  describe('getDiffFileByHash', () => {
    it('returns file by hash', () => {
      const fileA = {
        fileHash: '123',
      };
      const fileB = {
        fileHash: '456',
      };
      localState.diffFiles = [fileA, fileB];

      expect(getters.getDiffFileByHash(localState)('456')).toEqual(fileB);
    });

    it('returns null if no matching file is found', () => {
      localState.diffFiles = [];
      expect(getters.getDiffFileByHash(localState)('123')).toBeUndefined();
    });
  });

  describe('discussionsByLineCode', () => {
    let mockState;

    beforeEach(() => {
      mockState = { diffFiles: [diffFile] };
    });

    it('should return a map of diff lines with their line codes', () => {
      const mockGetters = { discussions: [discussionMock] };

      const map = getters.discussionsByLineCode(mockState, {}, {}, mockGetters);
      expect(map['1c497fbb3a46b78edf04cc2a2fa33f67e3ffbe2a_1_2']).toBeDefined();
      expect(Object.keys(map).length).toEqual(1);
    });

    it('should have the diff discussion on the map if the original position matches', () => {
      discussionMock.position.formatter.base_sha = 'ff9200';
      const mockGetters = { discussions: [discussionMock] };

      const map = getters.discussionsByLineCode(mockState, {}, {}, mockGetters);
      expect(map['1c497fbb3a46b78edf04cc2a2fa33f67e3ffbe2a_1_2']).toBeDefined();
      expect(Object.keys(map).length).toEqual(1);
    });

    it('should not add an outdated diff discussion to the returned map', () => {
      discussionMock.position.formatter.base_sha = 'ff9200';
      discussionMock.original_position.formatter.base_sha = 'ff9200';
      const mockGetters = { discussions: [discussionMock] };

      const map = getters.discussionsByLineCode(mockState, {}, {}, mockGetters);
      expect(Object.keys(map).length).toEqual(0);
    });
  });
});
