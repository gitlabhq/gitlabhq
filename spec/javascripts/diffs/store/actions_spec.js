import MockAdapter from 'axios-mock-adapter';
import Cookies from 'js-cookie';
import {
  DIFF_VIEW_COOKIE_NAME,
  INLINE_DIFF_VIEW_TYPE,
  PARALLEL_DIFF_VIEW_TYPE,
} from '~/diffs/constants';
import actions, {
  setBaseConfig,
  fetchDiffFiles,
  assignDiscussionsToDiff,
  removeDiscussionsFromDiff,
  startRenderDiffsQueue,
  setInlineDiffViewType,
  setParallelDiffViewType,
  showCommentForm,
  cancelCommentForm,
  loadMoreLines,
  scrollToLineIfNeededInline,
  scrollToLineIfNeededParallel,
  loadCollapsedDiff,
  expandAllFiles,
  toggleFileDiscussions,
  saveDiffDiscussion,
  toggleTreeOpen,
  scrollToFile,
  toggleShowTreeList,
} from '~/diffs/store/actions';
import * as types from '~/diffs/store/mutation_types';
import axios from '~/lib/utils/axios_utils';
import testAction from '../../helpers/vuex_action_helper';

describe('DiffsStoreActions', () => {
  const originalMethods = {
    requestAnimationFrame: global.requestAnimationFrame,
    requestIdleCallback: global.requestIdleCallback,
  };

  beforeEach(() => {
    ['requestAnimationFrame', 'requestIdleCallback'].forEach(method => {
      global[method] = cb => {
        cb();
      };
    });
  });

  afterEach(() => {
    ['requestAnimationFrame', 'requestIdleCallback'].forEach(method => {
      global[method] = originalMethods[method];
    });
  });

  describe('setBaseConfig', () => {
    it('should set given endpoint and project path', done => {
      const endpoint = '/diffs/set/endpoint';
      const projectPath = '/root/project';

      testAction(
        setBaseConfig,
        { endpoint, projectPath },
        { endpoint: '', projectPath: '' },
        [{ type: types.SET_BASE_CONFIG, payload: { endpoint, projectPath } }],
        [],
        done,
      );
    });
  });

  describe('fetchDiffFiles', () => {
    it('should fetch diff files', done => {
      const endpoint = '/fetch/diff/files';
      const mock = new MockAdapter(axios);
      const res = { diff_files: 1, merge_request_diffs: [] };
      mock.onGet(endpoint).reply(200, res);

      testAction(
        fetchDiffFiles,
        {},
        { endpoint },
        [
          { type: types.SET_LOADING, payload: true },
          { type: types.SET_LOADING, payload: false },
          { type: types.SET_MERGE_REQUEST_DIFFS, payload: res.merge_request_diffs },
          { type: types.SET_DIFF_DATA, payload: res },
        ],
        [],
        () => {
          mock.restore();
          done();
        },
      );
    });
  });

  describe('assignDiscussionsToDiff', () => {
    it('should merge discussions into diffs', done => {
      const state = {
        diffFiles: [
          {
            file_hash: 'ABC',
            parallel_diff_lines: [
              {
                left: {
                  line_code: 'ABC_1_1',
                  discussions: [],
                },
                right: {
                  line_code: 'ABC_1_1',
                  discussions: [],
                },
              },
            ],
            highlighted_diff_lines: [
              {
                line_code: 'ABC_1_1',
                discussions: [],
                old_line: 5,
                new_line: null,
              },
            ],
            diff_refs: {
              base_sha: 'abc',
              head_sha: 'def',
              start_sha: 'ghi',
            },
            new_path: 'file1',
            old_path: 'file2',
          },
        ],
      };

      const diffPosition = {
        base_sha: 'abc',
        head_sha: 'def',
        start_sha: 'ghi',
        new_line: null,
        new_path: 'file1',
        old_line: 5,
        old_path: 'file2',
      };

      const singleDiscussion = {
        line_code: 'ABC_1_1',
        diff_discussion: {},
        diff_file: {
          file_hash: 'ABC',
        },
        file_hash: 'ABC',
        resolvable: true,
        position: diffPosition,
        original_position: diffPosition,
      };

      const discussions = [singleDiscussion];

      testAction(
        assignDiscussionsToDiff,
        discussions,
        state,
        [
          {
            type: types.SET_LINE_DISCUSSIONS_FOR_FILE,
            payload: {
              discussion: singleDiscussion,
              diffPositionByLineCode: {
                ABC_1_1: {
                  base_sha: 'abc',
                  head_sha: 'def',
                  start_sha: 'ghi',
                  new_line: null,
                  new_path: 'file1',
                  old_line: 5,
                  old_path: 'file2',
                  line_code: 'ABC_1_1',
                  position_type: 'text',
                },
              },
            },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('removeDiscussionsFromDiff', () => {
    it('should remove discussions from diffs', done => {
      const state = {
        diffFiles: [
          {
            file_hash: 'ABC',
            parallel_diff_lines: [
              {
                left: {
                  line_code: 'ABC_1_1',
                  discussions: [
                    {
                      id: 1,
                    },
                  ],
                },
                right: {
                  line_code: 'ABC_1_1',
                  discussions: [],
                },
              },
            ],
            highlighted_diff_lines: [
              {
                line_code: 'ABC_1_1',
                discussions: [],
              },
            ],
          },
        ],
      };
      const singleDiscussion = {
        id: '1',
        file_hash: 'ABC',
        line_code: 'ABC_1_1',
      };

      testAction(
        removeDiscussionsFromDiff,
        singleDiscussion,
        state,
        [
          {
            type: types.REMOVE_LINE_DISCUSSIONS_FOR_FILE,
            payload: {
              id: '1',
              fileHash: 'ABC',
              lineCode: 'ABC_1_1',
            },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('startRenderDiffsQueue', () => {
    it('should set all files to RENDER_FILE', () => {
      const state = {
        diffFiles: [
          {
            id: 1,
            renderIt: false,
            collapsed: false,
          },
          {
            id: 2,
            renderIt: false,
            collapsed: false,
          },
        ],
      };

      const pseudoCommit = (commitType, file) => {
        expect(commitType).toBe(types.RENDER_FILE);
        Object.assign(file, {
          renderIt: true,
        });
      };

      startRenderDiffsQueue({ state, commit: pseudoCommit });

      expect(state.diffFiles[0].renderIt).toBe(true);
      expect(state.diffFiles[1].renderIt).toBe(true);
    });
  });

  describe('setInlineDiffViewType', () => {
    it('should set diff view type to inline and also set the cookie properly', done => {
      testAction(
        setInlineDiffViewType,
        null,
        {},
        [{ type: types.SET_DIFF_VIEW_TYPE, payload: INLINE_DIFF_VIEW_TYPE }],
        [],
        () => {
          setTimeout(() => {
            expect(Cookies.get('diff_view')).toEqual(INLINE_DIFF_VIEW_TYPE);
            done();
          }, 0);
        },
      );
    });
  });

  describe('setParallelDiffViewType', () => {
    it('should set diff view type to parallel and also set the cookie properly', done => {
      testAction(
        setParallelDiffViewType,
        null,
        {},
        [{ type: types.SET_DIFF_VIEW_TYPE, payload: PARALLEL_DIFF_VIEW_TYPE }],
        [],
        () => {
          setTimeout(() => {
            expect(Cookies.get(DIFF_VIEW_COOKIE_NAME)).toEqual(PARALLEL_DIFF_VIEW_TYPE);
            done();
          }, 0);
        },
      );
    });
  });

  describe('showCommentForm', () => {
    it('should call mutation to show comment form', done => {
      const payload = { lineCode: 'lineCode' };

      testAction(
        showCommentForm,
        payload,
        {},
        [{ type: types.ADD_COMMENT_FORM_LINE, payload }],
        [],
        done,
      );
    });
  });

  describe('cancelCommentForm', () => {
    it('should call mutation to cancel comment form', done => {
      const payload = { lineCode: 'lineCode' };

      testAction(
        cancelCommentForm,
        payload,
        {},
        [{ type: types.REMOVE_COMMENT_FORM_LINE, payload }],
        [],
        done,
      );
    });
  });

  describe('loadMoreLines', () => {
    it('should call mutation to show comment form', done => {
      const endpoint = '/diffs/load/more/lines';
      const params = { since: 6, to: 26 };
      const lineNumbers = { oldLineNumber: 3, newLineNumber: 5 };
      const fileHash = 'ff9200';
      const options = { endpoint, params, lineNumbers, fileHash };
      const mock = new MockAdapter(axios);
      const contextLines = { contextLines: [{ lineCode: 6 }] };
      mock.onGet(endpoint).reply(200, contextLines);

      testAction(
        loadMoreLines,
        options,
        {},
        [
          {
            type: types.ADD_CONTEXT_LINES,
            payload: { lineNumbers, contextLines, params, fileHash },
          },
        ],
        [],
        () => {
          mock.restore();
          done();
        },
      );
    });
  });

  describe('loadCollapsedDiff', () => {
    it('should fetch data and call mutation with response and the give parameter', done => {
      const file = { hash: 123, loadCollapsedDiffUrl: '/load/collapsed/diff/url' };
      const data = { hash: 123, parallelDiffLines: [{ lineCode: 1 }] };
      const mock = new MockAdapter(axios);
      mock.onGet(file.loadCollapsedDiffUrl).reply(200, data);

      testAction(
        loadCollapsedDiff,
        file,
        {},
        [
          {
            type: types.ADD_COLLAPSED_DIFFS,
            payload: { file, data },
          },
        ],
        [],
        () => {
          mock.restore();
          done();
        },
      );
    });
  });

  describe('expandAllFiles', () => {
    it('should change the collapsed prop from the diffFiles', done => {
      testAction(
        expandAllFiles,
        null,
        {},
        [
          {
            type: types.EXPAND_ALL_FILES,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('toggleFileDiscussions', () => {
    it('should dispatch collapseDiscussion when all discussions are expanded', () => {
      const getters = {
        getDiffFileDiscussions: jasmine.createSpy().and.returnValue([{ id: 1 }]),
        diffHasAllExpandedDiscussions: jasmine.createSpy().and.returnValue(true),
        diffHasAllCollpasedDiscussions: jasmine.createSpy().and.returnValue(false),
      };

      const dispatch = jasmine.createSpy('dispatch');

      toggleFileDiscussions({ getters, dispatch });

      expect(dispatch).toHaveBeenCalledWith(
        'collapseDiscussion',
        { discussionId: 1 },
        { root: true },
      );
    });

    it('should dispatch expandDiscussion when all discussions are collapsed', () => {
      const getters = {
        getDiffFileDiscussions: jasmine.createSpy().and.returnValue([{ id: 1 }]),
        diffHasAllExpandedDiscussions: jasmine.createSpy().and.returnValue(false),
        diffHasAllCollpasedDiscussions: jasmine.createSpy().and.returnValue(true),
      };

      const dispatch = jasmine.createSpy();

      toggleFileDiscussions({ getters, dispatch });

      expect(dispatch).toHaveBeenCalledWith(
        'expandDiscussion',
        { discussionId: 1 },
        { root: true },
      );
    });

    it('should dispatch expandDiscussion when some discussions are collapsed and others are expanded for the collapsed discussion', () => {
      const getters = {
        getDiffFileDiscussions: jasmine.createSpy().and.returnValue([{ expanded: false, id: 1 }]),
        diffHasAllExpandedDiscussions: jasmine.createSpy().and.returnValue(false),
        diffHasAllCollpasedDiscussions: jasmine.createSpy().and.returnValue(false),
      };

      const dispatch = jasmine.createSpy();

      toggleFileDiscussions({ getters, dispatch });

      expect(dispatch).toHaveBeenCalledWith(
        'expandDiscussion',
        { discussionId: 1 },
        { root: true },
      );
    });
  });

  describe('scrollToLineIfNeededInline', () => {
    const lineMock = {
      lineCode: 'ABC_123',
    };

    it('should not call handleLocationHash when there is not hash', () => {
      window.location.hash = '';

      const handleLocationHashSpy = spyOnDependency(actions, 'handleLocationHash').and.stub();

      scrollToLineIfNeededInline({}, lineMock);

      expect(handleLocationHashSpy).not.toHaveBeenCalled();
    });

    it('should not call handleLocationHash when the hash does not match any line', () => {
      window.location.hash = 'XYZ_456';

      const handleLocationHashSpy = spyOnDependency(actions, 'handleLocationHash').and.stub();

      scrollToLineIfNeededInline({}, lineMock);

      expect(handleLocationHashSpy).not.toHaveBeenCalled();
    });

    it('should call handleLocationHash only when the hash matches a line', () => {
      window.location.hash = 'ABC_123';

      const handleLocationHashSpy = spyOnDependency(actions, 'handleLocationHash').and.stub();

      scrollToLineIfNeededInline(
        {},
        {
          lineCode: 'ABC_456',
        },
      );
      scrollToLineIfNeededInline({}, lineMock);
      scrollToLineIfNeededInline(
        {},
        {
          lineCode: 'XYZ_456',
        },
      );

      expect(handleLocationHashSpy).toHaveBeenCalled();
      expect(handleLocationHashSpy).toHaveBeenCalledTimes(1);
    });
  });

  describe('scrollToLineIfNeededParallel', () => {
    const lineMock = {
      left: null,
      right: {
        lineCode: 'ABC_123',
      },
    };

    it('should not call handleLocationHash when there is not hash', () => {
      window.location.hash = '';

      const handleLocationHashSpy = spyOnDependency(actions, 'handleLocationHash').and.stub();

      scrollToLineIfNeededParallel({}, lineMock);

      expect(handleLocationHashSpy).not.toHaveBeenCalled();
    });

    it('should not call handleLocationHash when the hash does not match any line', () => {
      window.location.hash = 'XYZ_456';

      const handleLocationHashSpy = spyOnDependency(actions, 'handleLocationHash').and.stub();

      scrollToLineIfNeededParallel({}, lineMock);

      expect(handleLocationHashSpy).not.toHaveBeenCalled();
    });

    it('should call handleLocationHash only when the hash matches a line', () => {
      window.location.hash = 'ABC_123';

      const handleLocationHashSpy = spyOnDependency(actions, 'handleLocationHash').and.stub();

      scrollToLineIfNeededParallel(
        {},
        {
          left: null,
          right: {
            lineCode: 'ABC_456',
          },
        },
      );
      scrollToLineIfNeededParallel({}, lineMock);
      scrollToLineIfNeededParallel(
        {},
        {
          left: null,
          right: {
            lineCode: 'XYZ_456',
          },
        },
      );

      expect(handleLocationHashSpy).toHaveBeenCalled();
      expect(handleLocationHashSpy).toHaveBeenCalledTimes(1);
    });
  });

  describe('saveDiffDiscussion', () => {
    beforeEach(() => {
      spyOnDependency(actions, 'getNoteFormData').and.returnValue('testData');
    });

    it('dispatches actions', done => {
      const dispatch = jasmine.createSpy('dispatch').and.callFake(name => {
        switch (name) {
          case 'saveNote':
            return Promise.resolve({
              discussion: 'test',
            });
          case 'updateDiscussion':
            return Promise.resolve('discussion');
          default:
            return Promise.resolve({});
        }
      });

      saveDiffDiscussion({ dispatch }, { note: {}, formData: {} })
        .then(() => {
          expect(dispatch.calls.argsFor(0)).toEqual(['saveNote', 'testData', { root: true }]);
          expect(dispatch.calls.argsFor(1)).toEqual(['updateDiscussion', 'test', { root: true }]);
          expect(dispatch.calls.argsFor(2)).toEqual(['assignDiscussionsToDiff', ['discussion']]);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('toggleTreeOpen', () => {
    it('commits TOGGLE_FOLDER_OPEN', done => {
      testAction(
        toggleTreeOpen,
        'path',
        {},
        [{ type: types.TOGGLE_FOLDER_OPEN, payload: 'path' }],
        [],
        done,
      );
    });
  });

  describe('scrollToFile', () => {
    let commit;

    beforeEach(() => {
      commit = jasmine.createSpy();
      jasmine.clock().install();
    });

    afterEach(() => {
      jasmine.clock().uninstall();
    });

    it('updates location hash', () => {
      const state = {
        treeEntries: {
          path: {
            fileHash: 'test',
          },
        },
      };

      scrollToFile({ state, commit }, 'path');

      expect(document.location.hash).toBe('#test');
    });

    it('commits UPDATE_CURRENT_DIFF_FILE_ID', () => {
      const state = {
        treeEntries: {
          path: {
            fileHash: 'test',
          },
        },
      };

      scrollToFile({ state, commit }, 'path');

      expect(commit).toHaveBeenCalledWith(types.UPDATE_CURRENT_DIFF_FILE_ID, 'test');
    });

    it('resets currentDiffId after timeout', () => {
      const state = {
        treeEntries: {
          path: {
            fileHash: 'test',
          },
        },
      };

      scrollToFile({ state, commit }, 'path');

      jasmine.clock().tick(1000);

      expect(commit.calls.argsFor(1)).toEqual([types.UPDATE_CURRENT_DIFF_FILE_ID, '']);
    });
  });

  describe('toggleShowTreeList', () => {
    it('commits toggle', done => {
      testAction(toggleShowTreeList, null, {}, [{ type: types.TOGGLE_SHOW_TREE_LIST }], [], done);
    });

    it('updates localStorage', () => {
      spyOn(localStorage, 'setItem');

      toggleShowTreeList({ commit() {}, state: { showTreeList: true } });

      expect(localStorage.setItem).toHaveBeenCalledWith('mr_tree_show', true);
    });
  });
});
