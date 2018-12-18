import * as utils from '~/diffs/store/utils';
import {
  LINE_POSITION_LEFT,
  LINE_POSITION_RIGHT,
  TEXT_DIFF_POSITION_TYPE,
  LEGACY_DIFF_NOTE_TYPE,
  DIFF_NOTE_TYPE,
  NEW_LINE_TYPE,
  OLD_LINE_TYPE,
  MATCH_LINE_TYPE,
  PARALLEL_DIFF_VIEW_TYPE,
} from '~/diffs/constants';
import { MERGE_REQUEST_NOTEABLE_TYPE } from '~/notes/constants';
import diffFileMockData from '../mock_data/diff_file';
import { noteableDataMock } from '../../notes/mock_data';

const getDiffFileMock = () => Object.assign({}, diffFileMockData);

describe('DiffsStoreUtils', () => {
  describe('findDiffFile', () => {
    const files = [{ file_hash: 1, name: 'one' }];

    it('should return correct file', () => {
      expect(utils.findDiffFile(files, 1).name).toEqual('one');
      expect(utils.findDiffFile(files, 2)).toBeUndefined();
    });
  });

  describe('getReversePosition', () => {
    it('should return correct line position name', () => {
      expect(utils.getReversePosition(LINE_POSITION_RIGHT)).toEqual(LINE_POSITION_LEFT);
      expect(utils.getReversePosition(LINE_POSITION_LEFT)).toEqual(LINE_POSITION_RIGHT);
    });
  });

  describe('findIndexInInlineLines and findIndexInParallelLines', () => {
    const expectSet = (method, lines, invalidLines) => {
      expect(method(lines, { oldLineNumber: 3, newLineNumber: 5 })).toEqual(4);
      expect(method(invalidLines || lines, { oldLineNumber: 32, newLineNumber: 53 })).toEqual(-1);
    };

    describe('findIndexInInlineLines', () => {
      it('should return correct index for given line numbers', () => {
        expectSet(utils.findIndexInInlineLines, getDiffFileMock().highlighted_diff_lines);
      });
    });

    describe('findIndexInParallelLines', () => {
      it('should return correct index for given line numbers', () => {
        expectSet(utils.findIndexInParallelLines, getDiffFileMock().parallel_diff_lines, {});
      });
    });
  });

  describe('removeMatchLine', () => {
    it('should remove match line properly by regarding the bottom parameter', () => {
      const diffFile = getDiffFileMock();
      const lineNumbers = { oldLineNumber: 3, newLineNumber: 5 };
      const inlineIndex = utils.findIndexInInlineLines(
        diffFile.highlighted_diff_lines,
        lineNumbers,
      );
      const parallelIndex = utils.findIndexInParallelLines(
        diffFile.parallel_diff_lines,
        lineNumbers,
      );
      const atInlineIndex = diffFile.highlighted_diff_lines[inlineIndex];
      const atParallelIndex = diffFile.parallel_diff_lines[parallelIndex];

      utils.removeMatchLine(diffFile, lineNumbers, false);

      expect(diffFile.highlighted_diff_lines[inlineIndex]).not.toEqual(atInlineIndex);
      expect(diffFile.parallel_diff_lines[parallelIndex]).not.toEqual(atParallelIndex);

      utils.removeMatchLine(diffFile, lineNumbers, true);

      expect(diffFile.highlighted_diff_lines[inlineIndex + 1]).not.toEqual(atInlineIndex);
      expect(diffFile.parallel_diff_lines[parallelIndex + 1]).not.toEqual(atParallelIndex);
    });
  });

  describe('addContextLines', () => {
    it('should add context lines properly with bottom parameter', () => {
      const diffFile = getDiffFileMock();
      const inlineLines = diffFile.highlighted_diff_lines;
      const parallelLines = diffFile.parallel_diff_lines;
      const lineNumbers = { oldLineNumber: 3, newLineNumber: 5 };
      const contextLines = [{ lineNumber: 42 }];
      const options = { inlineLines, parallelLines, contextLines, lineNumbers, bottom: true };
      const inlineIndex = utils.findIndexInInlineLines(inlineLines, lineNumbers);
      const parallelIndex = utils.findIndexInParallelLines(parallelLines, lineNumbers);
      const normalizedParallelLine = {
        left: options.contextLines[0],
        right: options.contextLines[0],
      };

      utils.addContextLines(options);

      expect(inlineLines[inlineLines.length - 1]).toEqual(contextLines[0]);
      expect(parallelLines[parallelLines.length - 1]).toEqual(normalizedParallelLine);

      delete options.bottom;
      utils.addContextLines(options);

      expect(inlineLines[inlineIndex]).toEqual(contextLines[0]);
      expect(parallelLines[parallelIndex]).toEqual(normalizedParallelLine);
    });
  });

  describe('getNoteFormData', () => {
    it('should properly create note form data', () => {
      const diffFile = getDiffFileMock();
      noteableDataMock.targetType = MERGE_REQUEST_NOTEABLE_TYPE;

      const options = {
        note: 'Hello world!',
        noteableData: noteableDataMock,
        noteableType: MERGE_REQUEST_NOTEABLE_TYPE,
        diffFile,
        noteTargetLine: {
          line_code: '1c497fbb3a46b78edf04cc2a2fa33f67e3ffbe2a_1_3',
          meta_data: null,
          new_line: 3,
          old_line: 1,
        },
        diffViewType: PARALLEL_DIFF_VIEW_TYPE,
        linePosition: LINE_POSITION_LEFT,
      };

      const position = JSON.stringify({
        base_sha: diffFile.diff_refs.base_sha,
        start_sha: diffFile.diff_refs.start_sha,
        head_sha: diffFile.diff_refs.head_sha,
        old_path: diffFile.old_path,
        new_path: diffFile.new_path,
        position_type: TEXT_DIFF_POSITION_TYPE,
        old_line: options.noteTargetLine.old_line,
        new_line: options.noteTargetLine.new_line,
      });

      const postData = {
        view: options.diffViewType,
        line_type: options.linePosition === LINE_POSITION_RIGHT ? NEW_LINE_TYPE : OLD_LINE_TYPE,
        merge_request_diff_head_sha: diffFile.diff_refs.head_sha,
        in_reply_to_discussion_id: '',
        note_project_id: '',
        target_type: options.noteableType,
        target_id: options.noteableData.id,
        return_discussion: true,
        note: {
          noteable_type: options.noteableType,
          noteable_id: options.noteableData.id,
          commit_id: undefined,
          type: DIFF_NOTE_TYPE,
          line_code: options.noteTargetLine.line_code,
          note: options.note,
          position,
        },
      };

      expect(utils.getNoteFormData(options)).toEqual({
        endpoint: options.noteableData.create_note_path,
        data: postData,
      });
    });

    it('should create legacy note form data', () => {
      const diffFile = getDiffFileMock();
      delete diffFile.diff_refs.start_sha;
      delete diffFile.diff_refs.head_sha;

      noteableDataMock.targetType = MERGE_REQUEST_NOTEABLE_TYPE;

      const options = {
        note: 'Hello world!',
        noteableData: noteableDataMock,
        noteableType: MERGE_REQUEST_NOTEABLE_TYPE,
        diffFile,
        noteTargetLine: {
          line_code: '1c497fbb3a46b78edf04cc2a2fa33f67e3ffbe2a_1_3',
          meta_data: null,
          new_line: 3,
          old_line: 1,
        },
        diffViewType: PARALLEL_DIFF_VIEW_TYPE,
        linePosition: LINE_POSITION_LEFT,
      };

      const position = JSON.stringify({
        base_sha: diffFile.diff_refs.base_sha,
        start_sha: undefined,
        head_sha: undefined,
        old_path: diffFile.old_path,
        new_path: diffFile.new_path,
        position_type: TEXT_DIFF_POSITION_TYPE,
        old_line: options.noteTargetLine.old_line,
        new_line: options.noteTargetLine.new_line,
      });

      const postData = {
        view: options.diffViewType,
        line_type: options.linePosition === LINE_POSITION_RIGHT ? NEW_LINE_TYPE : OLD_LINE_TYPE,
        merge_request_diff_head_sha: undefined,
        in_reply_to_discussion_id: '',
        note_project_id: '',
        target_type: options.noteableType,
        target_id: options.noteableData.id,
        return_discussion: true,
        note: {
          noteable_type: options.noteableType,
          noteable_id: options.noteableData.id,
          commit_id: undefined,
          type: LEGACY_DIFF_NOTE_TYPE,
          line_code: options.noteTargetLine.line_code,
          note: options.note,
          position,
        },
      };

      expect(utils.getNoteFormData(options)).toEqual({
        endpoint: options.noteableData.create_note_path,
        data: postData,
      });
    });
  });

  describe('addLineReferences', () => {
    const lineNumbers = { oldLineNumber: 3, newLineNumber: 4 };

    it('should add correct line references when bottom set to true', () => {
      const lines = [{ type: null }, { type: MATCH_LINE_TYPE }];
      const linesWithReferences = utils.addLineReferences(lines, lineNumbers, true);

      expect(linesWithReferences[0].old_line).toEqual(lineNumbers.oldLineNumber + 1);
      expect(linesWithReferences[0].new_line).toEqual(lineNumbers.newLineNumber + 1);
      expect(linesWithReferences[1].meta_data.old_pos).toEqual(4);
      expect(linesWithReferences[1].meta_data.new_pos).toEqual(5);
    });

    it('should add correct line references when bottom falsy', () => {
      const lines = [{ type: null }, { type: MATCH_LINE_TYPE }, { type: null }];
      const linesWithReferences = utils.addLineReferences(lines, lineNumbers);

      expect(linesWithReferences[0].old_line).toEqual(0);
      expect(linesWithReferences[0].new_line).toEqual(1);
      expect(linesWithReferences[1].meta_data.old_pos).toEqual(2);
      expect(linesWithReferences[1].meta_data.new_pos).toEqual(3);
    });
  });

  describe('trimFirstCharOfLineContent', () => {
    it('trims the line when it starts with a space', () => {
      expect(utils.trimFirstCharOfLineContent({ rich_text: ' diff' })).toEqual({
        discussions: [],
        rich_text: 'diff',
      });
    });

    it('trims the line when it starts with a +', () => {
      expect(utils.trimFirstCharOfLineContent({ rich_text: '+diff' })).toEqual({
        discussions: [],
        rich_text: 'diff',
      });
    });

    it('trims the line when it starts with a -', () => {
      expect(utils.trimFirstCharOfLineContent({ rich_text: '-diff' })).toEqual({
        discussions: [],
        rich_text: 'diff',
      });
    });

    it('does not trims the line when it starts with a letter', () => {
      expect(utils.trimFirstCharOfLineContent({ rich_text: 'diff' })).toEqual({
        discussions: [],
        rich_text: 'diff',
      });
    });

    it('does not modify the provided object', () => {
      const lineObj = {
        discussions: [],
        rich_text: ' diff',
      };

      utils.trimFirstCharOfLineContent(lineObj);

      expect(lineObj).toEqual({ discussions: [], rich_text: ' diff' });
    });

    it('handles a undefined or null parameter', () => {
      expect(utils.trimFirstCharOfLineContent()).toEqual({ discussions: [] });
    });
  });

  describe('prepareDiffData', () => {
    let preparedDiff;

    beforeEach(() => {
      preparedDiff = { diff_files: [getDiffFileMock()] };
      utils.prepareDiffData(preparedDiff);
    });

    it('sets the renderIt and collapsed attribute on files', () => {
      const firstParallelDiffLine = preparedDiff.diff_files[0].parallel_diff_lines[2];

      expect(firstParallelDiffLine.left.discussions.length).toBe(0);
      expect(firstParallelDiffLine.left).not.toHaveAttr('text');
      expect(firstParallelDiffLine.right.discussions.length).toBe(0);
      expect(firstParallelDiffLine.right).not.toHaveAttr('text');
      const firstParallelChar = firstParallelDiffLine.right.rich_text.charAt(0);

      expect(firstParallelChar).not.toBe(' ');
      expect(firstParallelChar).not.toBe('+');
      expect(firstParallelChar).not.toBe('-');

      const checkLine = preparedDiff.diff_files[0].highlighted_diff_lines[0];

      expect(checkLine.discussions.length).toBe(0);
      expect(checkLine).not.toHaveAttr('text');
      const firstChar = checkLine.rich_text.charAt(0);

      expect(firstChar).not.toBe(' ');
      expect(firstChar).not.toBe('+');
      expect(firstChar).not.toBe('-');

      expect(preparedDiff.diff_files[0].renderIt).toBeTruthy();
      expect(preparedDiff.diff_files[0].collapsed).toBeFalsy();
    });

    it('adds line_code to all lines', () => {
      expect(
        preparedDiff.diff_files[0].parallel_diff_lines.filter(line => !line.line_code),
      ).toHaveLength(0);
    });

    it('uses right line code if left has none', () => {
      const firstLine = preparedDiff.diff_files[0].parallel_diff_lines[0];

      expect(firstLine.line_code).toEqual(firstLine.right.line_code);
    });
  });

  describe('isDiscussionApplicableToLine', () => {
    const diffPosition = {
      baseSha: 'ed13df29948c41ba367caa757ab3ec4892509910',
      headSha: 'b921914f9a834ac47e6fd9420f78db0f83559130',
      newLine: null,
      newPath: '500-lines-4.txt',
      oldLine: 5,
      oldPath: '500-lines-4.txt',
      startSha: 'ed13df29948c41ba367caa757ab3ec4892509910',
    };

    const wrongDiffPosition = {
      baseSha: 'wrong',
      headSha: 'wrong',
      newLine: null,
      newPath: '500-lines-4.txt',
      oldLine: 5,
      oldPath: '500-lines-4.txt',
      startSha: 'wrong',
    };

    const discussions = {
      upToDateDiscussion1: {
        original_position: diffPosition,
        position: wrongDiffPosition,
      },
      outDatedDiscussion1: {
        original_position: wrongDiffPosition,
        position: wrongDiffPosition,
      },
    };

    it('returns true when the discussion is up to date', () => {
      expect(
        utils.isDiscussionApplicableToLine({
          discussion: discussions.upToDateDiscussion1,
          diffPosition,
          latestDiff: true,
        }),
      ).toBe(true);
    });

    it('returns false when the discussion is not up to date', () => {
      expect(
        utils.isDiscussionApplicableToLine({
          discussion: discussions.outDatedDiscussion1,
          diffPosition,
          latestDiff: true,
        }),
      ).toBe(false);
    });

    it('returns true when line codes match and discussion does not contain position and is not active', () => {
      const discussion = { ...discussions.outDatedDiscussion1, line_code: 'ABC_1', active: false };
      delete discussion.original_position;
      delete discussion.position;

      expect(
        utils.isDiscussionApplicableToLine({
          discussion,
          diffPosition: {
            ...diffPosition,
            lineCode: 'ABC_1',
          },
          latestDiff: true,
        }),
      ).toBe(false);
    });

    it('returns true when line codes match and discussion does not contain position and is active', () => {
      const discussion = { ...discussions.outDatedDiscussion1, line_code: 'ABC_1', active: true };
      delete discussion.original_position;
      delete discussion.position;

      expect(
        utils.isDiscussionApplicableToLine({
          discussion,
          diffPosition: {
            ...diffPosition,
            line_code: 'ABC_1',
          },
          latestDiff: true,
        }),
      ).toBe(true);
    });

    it('returns false when not latest diff', () => {
      const discussion = { ...discussions.outDatedDiscussion1, line_code: 'ABC_1', active: true };
      delete discussion.original_position;
      delete discussion.position;

      expect(
        utils.isDiscussionApplicableToLine({
          discussion,
          diffPosition: {
            ...diffPosition,
            lineCode: 'ABC_1',
          },
          latestDiff: false,
        }),
      ).toBe(false);
    });
  });

  describe('generateTreeList', () => {
    let files;

    beforeAll(() => {
      files = [
        {
          new_path: 'app/index.js',
          deleted_file: false,
          new_file: false,
          removed_lines: 10,
          added_lines: 0,
          file_hash: 'test',
        },
        {
          new_path: 'app/test/index.js',
          deleted_file: false,
          new_file: true,
          removed_lines: 0,
          added_lines: 0,
          file_hash: 'test',
        },
        {
          new_path: 'app/test/filepathneedstruncating.js',
          deleted_file: false,
          new_file: true,
          removed_lines: 0,
          added_lines: 0,
          file_hash: 'test',
        },
        {
          new_path: 'package.json',
          deleted_file: true,
          new_file: false,
          removed_lines: 0,
          added_lines: 0,
          file_hash: 'test',
        },
      ];
    });

    it('creates a tree of files', () => {
      const { tree } = utils.generateTreeList(files);

      expect(tree).toEqual([
        {
          key: 'app',
          path: 'app',
          name: 'app',
          type: 'tree',
          tree: [
            {
              addedLines: 0,
              changed: true,
              deleted: false,
              fileHash: 'test',
              key: 'app/index.js',
              name: 'index.js',
              path: 'app/index.js',
              removedLines: 10,
              tempFile: false,
              type: 'blob',
              tree: [],
            },
            {
              key: 'app/test',
              path: 'app/test',
              name: 'test',
              type: 'tree',
              opened: true,
              tree: [
                {
                  addedLines: 0,
                  changed: true,
                  deleted: false,
                  fileHash: 'test',
                  key: 'app/test/index.js',
                  name: 'index.js',
                  path: 'app/test/index.js',
                  removedLines: 0,
                  tempFile: true,
                  type: 'blob',
                  tree: [],
                },
                {
                  addedLines: 0,
                  changed: true,
                  deleted: false,
                  fileHash: 'test',
                  key: 'app/test/filepathneedstruncating.js',
                  name: 'filepathneedstruncating.js',
                  path: 'app/test/filepathneedstruncating.js',
                  removedLines: 0,
                  tempFile: true,
                  type: 'blob',
                  tree: [],
                },
              ],
            },
          ],
          opened: true,
        },
        {
          key: 'package.json',
          path: 'package.json',
          name: 'package.json',
          type: 'blob',
          changed: true,
          tempFile: false,
          deleted: true,
          fileHash: 'test',
          addedLines: 0,
          removedLines: 0,
          tree: [],
        },
      ]);
    });

    it('creates flat list of blobs & folders', () => {
      const { treeEntries } = utils.generateTreeList(files);

      expect(Object.keys(treeEntries)).toEqual([
        'app',
        'app/index.js',
        'app/test',
        'app/test/index.js',
        'app/test/filepathneedstruncating.js',
        'package.json',
      ]);
    });
  });

  describe('getDiffMode', () => {
    it('returns mode when matched in file', () => {
      expect(
        utils.getDiffMode({
          renamed_file: true,
        }),
      ).toBe('renamed');
    });

    it('returns mode_changed if key has no match', () => {
      expect(
        utils.getDiffMode({
          mode_changed: true,
        }),
      ).toBe('mode_changed');
    });

    it('defaults to replaced', () => {
      expect(utils.getDiffMode({})).toBe('replaced');
    });
  });
});
