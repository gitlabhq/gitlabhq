/* global BoardService */

export const boardObj = {
  id: 1,
  name: 'test',
  milestone_id: null,
};

export const listObj = {
  id: 300,
  position: 0,
  title: 'Test',
  list_type: 'label',
  label: {
    id: 5000,
    title: 'Testing',
    color: 'red',
    description: 'testing;',
  },
};

export const listObjDuplicate = {
  id: listObj.id,
  position: 1,
  title: 'Test',
  list_type: 'label',
  label: {
    id: listObj.label.id,
    title: 'Testing',
    color: 'red',
    description: 'testing;',
  },
};

export const BoardsMockData = {
  GET: {
    '/test/-/boards/1/lists/300/issues?id=300&page=1&=': {
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
    '/test/issue-boards/milestones.json': [
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
    '/test/issue-boards/board/1/lists{/id}': {},
  },
  DELETE: {
    '/test/issue-boards/board/1/lists{/id}': {},
  },
};

export const boardsMockInterceptor = config => {
  const body = BoardsMockData[config.method.toUpperCase()][config.url];
  return [200, body];
};

export const mockBoardService = (opts = {}) => {
  const boardsEndpoint = opts.boardsEndpoint || '/test/issue-boards/boards.json';
  const listsEndpoint = opts.listsEndpoint || '/test/-/boards/1/lists';
  const bulkUpdatePath = opts.bulkUpdatePath || '';
  const boardId = opts.boardId || '1';

  return new BoardService({
    boardsEndpoint,
    listsEndpoint,
    bulkUpdatePath,
    boardId,
  });
};
