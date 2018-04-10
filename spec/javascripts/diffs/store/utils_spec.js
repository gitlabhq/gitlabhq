import * as utils from '~/diffs/store/utils';
import {
  LINE_POSITION_LEFT,
  LINE_POSITION_RIGHT,
  TEXT_DIFF_POSITION_TYPE,
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
    const files = [{ fileHash: 1, name: 'one' }];

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
        expectSet(utils.findIndexInInlineLines, getDiffFileMock().highlightedDiffLines);
      });
    });

    describe('findIndexInParallelLines', () => {
      it('should return correct index for given line numbers', () => {
        expectSet(utils.findIndexInParallelLines, getDiffFileMock().parallelDiffLines, {});
      });
    });
  });

  describe('removeMatchLine', () => {
    it('should remove match line properly by regarding the bottom parameter', () => {
      const diffFile = getDiffFileMock();
      const lineNumbers = { oldLineNumber: 3, newLineNumber: 5 };
      const inlineIndex = utils.findIndexInInlineLines(diffFile.highlightedDiffLines, lineNumbers);
      const parallelIndex = utils.findIndexInParallelLines(diffFile.parallelDiffLines, lineNumbers);
      const atInlineIndex = diffFile.highlightedDiffLines[inlineIndex];
      const atParallelIndex = diffFile.parallelDiffLines[parallelIndex];

      utils.removeMatchLine(diffFile, lineNumbers, false);
      expect(diffFile.highlightedDiffLines[inlineIndex]).not.toEqual(atInlineIndex);
      expect(diffFile.parallelDiffLines[parallelIndex]).not.toEqual(atParallelIndex);

      utils.removeMatchLine(diffFile, lineNumbers, true);
      expect(diffFile.highlightedDiffLines[inlineIndex + 1]).not.toEqual(atInlineIndex);
      expect(diffFile.parallelDiffLines[parallelIndex + 1]).not.toEqual(atParallelIndex);
    });
  });

  describe('addContextLines', () => {
    it('should add context lines properly with bottom parameter', () => {
      const diffFile = getDiffFileMock();
      const inlineLines = diffFile.highlightedDiffLines;
      const parallelLines = diffFile.parallelDiffLines;
      const lineNumbers = { oldLineNumber: 3, newLineNumber: 5 };
      const contextLines = [{ lineNumber: 42 }];
      const options = { inlineLines, parallelLines, contextLines, lineNumbers, bottom: true };
      const inlineIndex = utils.findIndexInInlineLines(diffFile.highlightedDiffLines, lineNumbers);
      const parallelIndex = utils.findIndexInParallelLines(diffFile.parallelDiffLines, lineNumbers);
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
      const options = {
        note: 'Hello world!',
        noteableData: noteableDataMock,
        noteableType: MERGE_REQUEST_NOTEABLE_TYPE,
        diffFile,
        noteTargetLine: {
          lineCode: '1c497fbb3a46b78edf04cc2a2fa33f67e3ffbe2a_1_3',
          metaData: null,
          newLine: 3,
          oldLine: 1,
        },
        diffViewType: PARALLEL_DIFF_VIEW_TYPE,
        linePosition: LINE_POSITION_LEFT,
      };

      const position = JSON.stringify({
        base_sha: diffFile.diffRefs.baseSha,
        start_sha: diffFile.diffRefs.startSha,
        head_sha: diffFile.diffRefs.headSha,
        old_path: diffFile.oldPath,
        new_path: diffFile.newPath,
        position_type: TEXT_DIFF_POSITION_TYPE,
        old_line: options.noteTargetLine.oldLine,
        new_line: options.noteTargetLine.newLine,
      });

      const postData = {
        view: options.diffViewType,
        line_type: options.linePosition === LINE_POSITION_RIGHT ? NEW_LINE_TYPE : OLD_LINE_TYPE,
        merge_request_diff_head_sha: diffFile.diffRefs.headSha,
        in_reply_to_discussion_id: '',
        note_project_id: '',
        target_type: options.noteableType,
        target_id: options.noteableData.id,
        'note[noteable_type]': options.noteableType,
        'note[noteable_id]': options.noteableData.id,
        'note[commit_id]': '',
        'note[type]': DIFF_NOTE_TYPE,
        'note[line_code]': options.noteTargetLine.lineCode,
        'note[note]': options.note,
        'note[position]': position,
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

      expect(linesWithReferences[0].oldLine).toEqual(lineNumbers.oldLineNumber + 1);
      expect(linesWithReferences[0].newLine).toEqual(lineNumbers.newLineNumber + 1);
      expect(linesWithReferences[1].metaData.oldPos).toEqual(4);
      expect(linesWithReferences[1].metaData.newPos).toEqual(5);
    });

    it('should add correct line references when bottom falsy', () => {
      const lines = [{ type: null }, { type: MATCH_LINE_TYPE }, { type: null }];
      const linesWithReferences = utils.addLineReferences(lines, lineNumbers);

      expect(linesWithReferences[0].oldLine).toEqual(0);
      expect(linesWithReferences[0].newLine).toEqual(1);
      expect(linesWithReferences[1].metaData.oldPos).toEqual(2);
      expect(linesWithReferences[1].metaData.newPos).toEqual(3);
    });
  });
});
