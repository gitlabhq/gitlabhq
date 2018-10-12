import mutations from '~/diffs/store/mutations';
import * as types from '~/diffs/store/mutation_types';
import { INLINE_DIFF_VIEW_TYPE } from '~/diffs/constants';
import diffFileMockData from '../mock_data/diff_file';

describe('DiffsStoreMutations', () => {
  describe('SET_BASE_CONFIG', () => {
    it('should set endpoint and project path', () => {
      const state = {};
      const endpoint = '/diffs/endpoint';
      const projectPath = '/root/project';

      mutations[types.SET_BASE_CONFIG](state, { endpoint, projectPath });
      expect(state.endpoint).toEqual(endpoint);
      expect(state.projectPath).toEqual(projectPath);
    });
  });

  describe('SET_LOADING', () => {
    it('should set loading state', () => {
      const state = {};

      mutations[types.SET_LOADING](state, false);
      expect(state.isLoading).toEqual(false);
    });
  });

  describe('SET_DIFF_DATA', () => {
    it('should set diff data type properly', () => {
      const state = {};
      const diffMock = {
        diff_files: [diffFileMockData],
      };

      mutations[types.SET_DIFF_DATA](state, diffMock);

      const firstLine = state.diffFiles[0].parallelDiffLines[0];

      expect(firstLine.right.text).toBeUndefined();
      expect(state.diffFiles[0].renderIt).toEqual(true);
      expect(state.diffFiles[0].collapsed).toEqual(false);
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

  describe('EXPAND_ALL_FILES', () => {
    it('should change the collapsed prop from diffFiles', () => {
      const diffFile = {
        collapsed: true,
      };
      const state = { expandAllFiles: true, diffFiles: [diffFile] };

      mutations[types.EXPAND_ALL_FILES](state);
      expect(state.diffFiles[0].collapsed).toEqual(false);
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

      const findDiffFileSpy = spyOnDependency(mutations, 'findDiffFile').and.returnValue(diffFile);
      const removeMatchLineSpy = spyOnDependency(mutations, 'removeMatchLine');
      const lineRefSpy = spyOnDependency(mutations, 'addLineReferences').and.returnValue(lines);
      const addContextLinesSpy = spyOnDependency(mutations, 'addContextLines');

      mutations[types.ADD_CONTEXT_LINES](state, options);

      expect(findDiffFileSpy).toHaveBeenCalledWith(state.diffFiles, options.fileHash);
      expect(removeMatchLineSpy).toHaveBeenCalledWith(
        diffFile,
        options.lineNumbers,
        options.params.bottom,
      );
      expect(lineRefSpy).toHaveBeenCalledWith(
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

  describe('ADD_COLLAPSED_DIFFS', () => {
    it('should update the state with the given data for the given file hash', () => {
      const spy = spyOnDependency(mutations, 'convertObjectPropsToCamelCase').and.callThrough();

      const fileHash = 123;
      const state = { diffFiles: [{}, { fileHash, existingField: 0 }] };
      const data = { diff_files: [{ file_hash: fileHash, extra_field: 1, existingField: 1 }] };

      mutations[types.ADD_COLLAPSED_DIFFS](state, { file: state.diffFiles[1], data });
      expect(spy).toHaveBeenCalledWith(data, { deep: true });

      expect(state.diffFiles[1].fileHash).toEqual(fileHash);
      expect(state.diffFiles[1].existingField).toEqual(1);
      expect(state.diffFiles[1].extraField).toEqual(1);
    });
  });

  describe('SET_LINE_DISCUSSIONS_FOR_FILE', () => {
    it('should add discussions to the given line', () => {
      const diffPosition = {
        baseSha: 'ed13df29948c41ba367caa757ab3ec4892509910',
        headSha: 'b921914f9a834ac47e6fd9420f78db0f83559130',
        newLine: null,
        newPath: '500-lines-4.txt',
        oldLine: 5,
        oldPath: '500-lines-4.txt',
        startSha: 'ed13df29948c41ba367caa757ab3ec4892509910',
      };

      const state = {
        diffFiles: [
          {
            fileHash: 'ABC',
            parallelDiffLines: [
              {
                left: {
                  lineCode: 'ABC_1',
                  discussions: [],
                },
                right: {
                  lineCode: 'ABC_1',
                  discussions: [],
                },
              },
            ],
            highlightedDiffLines: [
              {
                lineCode: 'ABC_1',
                discussions: [],
              },
            ],
          },
        ],
      };
      const discussions = [
        {
          id: 1,
          line_code: 'ABC_1',
          diff_discussion: true,
          resolvable: true,
          original_position: {
            formatter: diffPosition,
          },
          position: {
            formatter: diffPosition,
          },
        },
        {
          id: 2,
          line_code: 'ABC_1',
          diff_discussion: true,
          resolvable: true,
          original_position: {
            formatter: diffPosition,
          },
          position: {
            formatter: diffPosition,
          },
        },
      ];

      const diffPositionByLineCode = {
        ABC_1: diffPosition,
      };

      mutations[types.SET_LINE_DISCUSSIONS_FOR_FILE](state, {
        fileHash: 'ABC',
        discussions,
        diffPositionByLineCode,
      });

      expect(state.diffFiles[0].parallelDiffLines[0].left.discussions.length).toEqual(2);
      expect(state.diffFiles[0].parallelDiffLines[0].left.discussions[1].id).toEqual(2);

      expect(state.diffFiles[0].highlightedDiffLines[0].discussions.length).toEqual(2);
      expect(state.diffFiles[0].highlightedDiffLines[0].discussions[1].id).toEqual(2);
    });
  });

  describe('REMOVE_LINE_DISCUSSIONS', () => {
    it('should remove the existing discussions on the given line', () => {
      const state = {
        diffFiles: [
          {
            fileHash: 'ABC',
            parallelDiffLines: [
              {
                left: {
                  lineCode: 'ABC_1',
                  discussions: [
                    {
                      id: 1,
                      line_code: 'ABC_1',
                    },
                    {
                      id: 2,
                      line_code: 'ABC_1',
                    },
                  ],
                },
                right: {
                  lineCode: 'ABC_1',
                  discussions: [],
                },
              },
            ],
            highlightedDiffLines: [
              {
                lineCode: 'ABC_1',
                discussions: [
                  {
                    id: 1,
                    line_code: 'ABC_1',
                  },
                  {
                    id: 2,
                    line_code: 'ABC_1',
                  },
                ],
              },
            ],
          },
        ],
      };

      mutations[types.REMOVE_LINE_DISCUSSIONS_FOR_FILE](state, {
        fileHash: 'ABC',
        lineCode: 'ABC_1',
      });
      expect(state.diffFiles[0].parallelDiffLines[0].left.discussions.length).toEqual(0);
      expect(state.diffFiles[0].highlightedDiffLines[0].discussions.length).toEqual(0);
    });
  });
});
