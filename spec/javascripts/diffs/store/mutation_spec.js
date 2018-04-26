import mutations from '~/diffs/store/mutations';
import * as utils from '~/diffs/store/utils';
import * as types from '~/diffs/store/mutation_types';
import { INLINE_DIFF_VIEW_TYPE } from '~/diffs/constants';

describe('DiffsStoreMutations', () => {
  describe('SET_ENDPOINT', () => {
    it('should set endpoint', () => {
      const state = {};
      const endpoint = '/diffs/endpoint';

      mutations[types.SET_ENDPOINT](state, endpoint);
      expect(state.endpoint).toEqual(endpoint);
    });
  });

  describe('SET_LOADING', () => {
    it('should set loading state', () => {
      const state = {};

      mutations[types.SET_LOADING](state, false);
      expect(state.isLoading).toEqual(false);
    });
  });

  describe('SET_DIFF_FILES', () => {
    it('should set diff files to state', () => {
      const filePath = '/first-diff-file-path';
      const state = {};
      const diffFiles = {
        a_mode: 1,
        highlighted_diff_lines: [{ file_path: filePath }],
      };

      mutations[types.SET_DIFF_FILES](state, diffFiles);
      expect(state.diffFiles.aMode).toEqual(1);
      expect(state.diffFiles.highlightedDiffLines[0].filePath).toEqual(filePath);
    });
  });

  describe('SET_DIFF_VIEW_TYPE', () => {
    it('should set diff view type properly', () => {
      const state = {};

      mutations[types.SET_DIFF_VIEW_TYPE](state, INLINE_DIFF_VIEW_TYPE);
      expect(state.diffViewType).toEqual(INLINE_DIFF_VIEW_TYPE);
    });
  });

  describe('ADD_COMMENT_FORM_LINE', () => {
    it('should set a truthy reference for the given line code in diffLineCommentForms', () => {
      const state = { diffLineCommentForms: {} };
      const lineCode = 'FDE';

      mutations[types.ADD_COMMENT_FORM_LINE](state, { lineCode });
      expect(state.diffLineCommentForms[lineCode]).toBeTruthy();
    });
  });

  describe('REMOVE_COMMENT_FORM_LINE', () => {
    it('should remove given reference from diffLineCommentForms', () => {
      const state = { diffLineCommentForms: {} };
      const lineCode = 'FDE';

      mutations[types.ADD_COMMENT_FORM_LINE](state, { lineCode });
      expect(state.diffLineCommentForms[lineCode]).toBeTruthy();

      mutations[types.REMOVE_COMMENT_FORM_LINE](state, { lineCode });
      expect(state.diffLineCommentForms[lineCode]).toBeUndefined();
    });
  });

  describe('ADD_CONTEXT_LINES', () => {
    it('should call utils.addContextLines with proper params', () => {
      const options = {
        lineNumbers: { oldLineNumber: 1, newLineNumber: 2 },
        contextLines: [{ oldLine: 1 }],
        fileHash: 'ff9200',
        params: {
          bottom: true,
        },
      };
      const diffFile = {
        fileHash: options.fileHash,
        highlightedDiffLines: [],
        parallelDiffLines: [],
      };
      const state = { diffFiles: [diffFile] };
      const lines = [{ oldLine: 1 }];

      const findDiffFileSpy = spyOn(utils, 'findDiffFile').and.returnValue(diffFile);
      const removeMatchLineSpy = spyOn(utils, 'removeMatchLine');
      const addLineReferences = spyOn(utils, 'addLineReferences').and.returnValue(lines);
      const addContextLinesSpy = spyOn(utils, 'addContextLines');

      mutations[types.ADD_CONTEXT_LINES](state, options);

      expect(findDiffFileSpy).toHaveBeenCalledWith(state.diffFiles, options.fileHash);
      expect(removeMatchLineSpy).toHaveBeenCalledWith(
        diffFile,
        options.lineNumbers,
        options.params.bottom,
      );
      expect(addLineReferences).toHaveBeenCalledWith(
        options.contextLines,
        options.lineNumbers,
        options.params.bottom,
      );
      expect(addContextLinesSpy).toHaveBeenCalledWith({
        inlineLines: diffFile.highlightedDiffLines,
        parallelLines: diffFile.parallelDiffLines,
        contextLines: options.contextLines,
        bottom: options.params.bottom,
        lineNumbers: options.lineNumbers,
      });
    });
  });
});
