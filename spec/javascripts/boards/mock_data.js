/* eslint-disable comma-dangle, no-unused-vars, quote-props */

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
    '/test/issue-boards/board/1/lists{/id}/issues': {
      issues: [{
        title: 'Testing',
        iid: 1,
        confidential: false,
        labels: [],
        assignees: [],
      }],
      size: 1
    }
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
  const body = BoardsMockData[request.method][request.url];

  next(request.respondWith(JSON.stringify(body), {
    status: 200
  }));
};

window.listObj = listObj;
window.listObjDuplicate = listObjDuplicate;
window.BoardsMockData = BoardsMockData;
window.boardsMockInterceptor = boardsMockInterceptor;
