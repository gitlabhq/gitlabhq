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

describe('Issue model', () => {
  let issue;

  beforeEach(() => {
    gl.boardService = new BoardService('/test/issue-boards/board');
    BoardsStore.create();

    issue = new Issue({
      title: 'Testing',
      iid: 1,
      confidential: false,
      labels: [{
        id: 1,
        title: 'test',
        color: 'red',
        description: 'testing'
      }]
    });
  });

  it('has label', () => {
    expect(issue.labels.length).toBe(1);
  });

  it('add new label', () => {
    issue.addLabel({
      id: 2,
      title: 'bug',
      color: 'blue',
      description: 'bugs!'
    });
    expect(issue.labels.length).toBe(2);
  });

  it('does not add existing label', () => {
    issue.addLabel({
      id: 2,
      title: 'test',
      color: 'blue',
      description: 'bugs!'
    });

    expect(issue.labels.length).toBe(1);
  });

  it('finds label', () => {
    const label = issue.findLabel(issue.labels[0]);
    expect(label).toBeDefined();
  });

  it('removes label', () => {
    const label = issue.findLabel(issue.labels[0]);
    issue.removeLabel(label);
    expect(issue.labels.length).toBe(0);
  });

  it('removes multiple labels', () => {
    issue.addLabel({
      id: 2,
      title: 'bug',
      color: 'blue',
      description: 'bugs!'
    });
    expect(issue.labels.length).toBe(2);

    issue.removeLabels([issue.labels[0], issue.labels[1]]);
    expect(issue.labels.length).toBe(0);
  });
});
