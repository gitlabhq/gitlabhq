//= require jquery
//= require jquery_ujs
//= require jquery.cookie
//= require vue
//= require vue-resource
//= require lib/utils/url_utility
//= require boards/models/issue
//= require boards/models/label
//= require boards/models/list
//= require boards/models/user
//= require boards/services/board_service
//= require boards/stores/boards_store
//= require ./mock_data

describe('List model', () => {
  let list;

  beforeEach(() => {
    gl.boardService = new BoardService('/test/issue-boards/board');
    BoardsStore.create();

    list = new List(listObj);
  });

  it('gets issues when created', (done) => {
    setTimeout(() => {
      expect(list.issues.length).toBe(1);
      done();
    }, 0);
  });

  it('saves list and returns ID', (done) => {
    list = new List({
      title: 'test',
      label: {
        id: 1,
        title: 'test',
        color: 'red'
      }
    });
    list.save();

    setTimeout(() => {
      expect(list.id).toBe(1);
      expect(list.type).toBe('label');
      expect(list.position).toBe(0);
      done();
    }, 0);
  });

  it('destroys the list', (done) => {
    BoardsStore.addList(listObj);
    list = BoardsStore.findList('id', 1);
    expect(BoardsStore.state.lists.length).toBe(1);
    list.destroy();

    setTimeout(() => {
      expect(BoardsStore.state.lists.length).toBe(0);
      done();
    }, 0);
  });

  it('can\'t search when not backlog', () => {
    expect(list.canSearch()).toBe(false);
  });

  it('can search when backlog', () => {
    list.type = 'backlog';
    expect(list.canSearch()).toBe(true);
  });

  it('gets issue from list', (done) => {
    setTimeout(() => {
      const issue = list.findIssue(1);
      expect(issue).toBeDefined();
      done();
    }, 0);
  });

  it('removes issue', (done) => {
    setTimeout(() => {
      const issue = list.findIssue(1);
      expect(list.issues.length).toBe(1);
      list.removeIssue(issue);
      expect(list.issues.length).toBe(0);
      done();
    }, 0);
  });
});
