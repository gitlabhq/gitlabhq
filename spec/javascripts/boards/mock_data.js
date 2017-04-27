/* eslint-disable comma-dangle, no-unused-vars, quote-props */
const boardObj = {
  id: 1,
  name: 'test',
  milestone_id: null,
};

const listObj = {
  id: 1,
  position: 0,
  title: 'Test',
  list_type: 'label',
  label: {
    id: 1,
    title: 'Testing',
    color: 'red',
    description: 'testing;'
  }
};

const listObjDuplicate = {
  id: 2,
  position: 1,
  title: 'Test',
  list_type: 'label',
  label: {
    id: 2,
    title: 'Testing',
    color: 'red',
    description: 'testing;'
  }
};

const BoardsMockData = {
  'GET': {
    '/test/issue-boards/board/1/lists{/id}/issues': {
      issues: [{
        title: 'Testing',
        iid: 1,
        confidential: false,
        labels: [],
        assignees: [],
      }],
      size: 1
    },
    '/test/issue-boards/milestones.json': [{
      id: 1,
      title: 'test',
    }],
  },
  'POST': {
    '/test/issue-boards/board/1/lists{/id}': listObj
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
