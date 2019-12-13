import boardsStore from '~/boards/stores/boards_store';
import { listObj } from '../../frontend/boards/mock_data';

export * from '../../frontend/boards/mock_data';

export const BoardsMockData = {
  GET: {
    '/test/-/boards/1/lists/300/issues?id=300&page=1': {
      issues: [
        {
          title: 'Testing',
          id: 1,
          iid: 1,
          confidential: false,
          labels: [],
          assignees: [],
        },
      ],
    },
    '/test/issue-boards/-/milestones.json': [
      {
        id: 1,
        title: 'test',
      },
    ],
  },
  POST: {
    '/test/-/boards/1/lists': listObj,
  },
  PUT: {
    '/test/issue-boards/-/board/1/lists{/id}': {},
  },
  DELETE: {
    '/test/issue-boards/-/board/1/lists{/id}': {},
  },
};

export const boardsMockInterceptor = config => {
  const body = BoardsMockData[config.method.toUpperCase()][config.url];
  return [200, body];
};

export const setMockEndpoints = (opts = {}) => {
  const boardsEndpoint = opts.boardsEndpoint || '/test/issue-boards/-/boards.json';
  const listsEndpoint = opts.listsEndpoint || '/test/-/boards/1/lists';
  const bulkUpdatePath = opts.bulkUpdatePath || '';
  const boardId = opts.boardId || '1';

  boardsStore.setEndpoints({
    boardsEndpoint,
    listsEndpoint,
    bulkUpdatePath,
    boardId,
  });
};
