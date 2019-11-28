import BoardService from '~/boards/services/board_service';
import boardsStore from '~/boards/stores/boards_store';

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
  weight: 3,
  label: {
    id: 5000,
    title: 'Test',
    color: 'red',
    description: 'testing;',
    textColor: 'white',
  },
};

export const listObjDuplicate = {
  id: listObj.id,
  position: 1,
  title: 'Test',
  list_type: 'label',
  weight: 3,
  label: {
    id: listObj.label.id,
    title: 'Test',
    color: 'red',
    description: 'testing;',
  },
};

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

export const mockBoardService = (opts = {}) => {
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

  return new BoardService();
};

export const mockAssigneesList = [
  {
    id: 2,
    name: 'Terrell Graham',
    username: 'monserrate.gleichner',
    state: 'active',
    avatar_url: 'https://www.gravatar.com/avatar/598fd02741ac58b88854a99d16704309?s=80&d=identicon',
    web_url: 'http://127.0.0.1:3001/monserrate.gleichner',
    path: '/monserrate.gleichner',
  },
  {
    id: 12,
    name: 'Susy Johnson',
    username: 'tana_harvey',
    state: 'active',
    avatar_url: 'https://www.gravatar.com/avatar/e021a7b0f3e4ae53b5068d487e68c031?s=80&d=identicon',
    web_url: 'http://127.0.0.1:3001/tana_harvey',
    path: '/tana_harvey',
  },
  {
    id: 20,
    name: 'Conchita Eichmann',
    username: 'juliana_gulgowski',
    state: 'active',
    avatar_url: 'https://www.gravatar.com/avatar/c43c506cb6fd7b37017d3b54b94aa937?s=80&d=identicon',
    web_url: 'http://127.0.0.1:3001/juliana_gulgowski',
    path: '/juliana_gulgowski',
  },
  {
    id: 6,
    name: 'Bryce Turcotte',
    username: 'melynda',
    state: 'active',
    avatar_url: 'https://www.gravatar.com/avatar/cc2518f2c6f19f8fac49e1a5ee092a9b?s=80&d=identicon',
    web_url: 'http://127.0.0.1:3001/melynda',
    path: '/melynda',
  },
  {
    id: 1,
    name: 'Administrator',
    username: 'root',
    state: 'active',
    avatar_url: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
    web_url: 'http://127.0.0.1:3001/root',
    path: '/root',
  },
];

export const mockMilestone = {
  id: 1,
  state: 'active',
  title: 'Milestone title',
  description: 'Harum corporis aut consequatur quae dolorem error sequi quia.',
  start_date: '2018-01-01',
  due_date: '2019-12-31',
};
