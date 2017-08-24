/* global BoardService */
/* eslint-disable comma-dangle, no-unused-vars, quote-props */
const boardObj = {
  id: 1,
  name: 'test',
  milestone_id: null,
};

const listObj = {
  id: _.random(10000),
  position: 0,
  title: 'Test',
  list_type: 'label',
  label: {
    id: _.random(10000),
    title: 'Testing',
    color: 'red',
    description: 'testing;'
  }
};

const listObjDuplicate = {
  id: listObj.id,
  position: 1,
  title: 'Test',
  list_type: 'label',
  label: {
    id: listObj.label.id,
    title: 'Testing',
    color: 'red',
    description: 'testing;'
  }
};

const BoardsMockData = {
  'GET': {
    '/test/boards/1{/id}/issues': {
      issues: [{
        title: 'Testing',
        id: 1,
        iid: 1,
        confidential: false,
        labels: [],
        assignees: [],
      }],
    },
    '/test/issue-boards/milestones.json': [{
      id: 1,
      title: 'test',
    }],
  },
  'POST': {
    '/test/boards/1{/id}': listObj
  },
  'PUT': {
    '/test/issue-boards/board/1/lists{/id}': {}
  },
  'DELETE': {
    '/test/issue-boards/board/1/lists{/id}': {}
  }
};

const boardsMockInterceptor = (request, next) => {
  const body = BoardsMockData[request.method.toUpperCase()][request.url];

  next(request.respondWith(JSON.stringify(body), {
    status: 200
  }));
};

window.boardObj = boardObj;
window.listObj = listObj;
window.listObjDuplicate = listObjDuplicate;
window.BoardsMockData = BoardsMockData;
window.boardsMockInterceptor = boardsMockInterceptor;

// eslint-disable-next-line import/prefer-default-export
export function mockBoardService(opts = {}) {
  const boardsEndpoint = opts.boardsEndpoint || '/test/issue-boards/board';
  const listsEndpoint = opts.listsEndpoint || '/test/boards/1';
  const bulkUpdatePath = opts.bulkUpdatePath || '';
  const boardId = opts.boardId || '1';

  return new BoardService({
    boardsEndpoint,
    listsEndpoint,
    bulkUpdatePath,
    boardId,
  });
}
