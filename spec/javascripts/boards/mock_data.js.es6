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
    '/test/issue-boards/board/lists{/id}/issues': {
      issues: [{
        title: 'Testing',
        iid: 1,
        confidential: false,
        labels: []
      }],
      size: 1
    }
  },
  'POST': {
    '/test/issue-boards/board/lists{/id}': listObj
  },
  'PUT': {
    '/test/issue-boards/board/lists{/id}': {}
  },
  'DELETE': {
    '/test/issue-boards/board/lists{/id}': {}
  }
};

Vue.http.interceptors.push((request, next) => {
  const body = BoardsMockData[request.method][request.url];

  next(request.respondWith(JSON.stringify(body), {
    status: 200
  }));
});
