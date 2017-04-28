/* eslint-disable comma-dangle */
/* global BoardService */
/* global ListIssue */

import '~/lib/utils/url_utility';
import '~/boards/models/issue';
import '~/boards/models/label';
import '~/boards/models/list';
import '~/boards/models/assignee';
import '~/boards/services/board_service';
import '~/boards/stores/boards_store';
import './mock_data';

describe('Issue model', () => {
  let issue;

  beforeEach(() => {
    gl.boardService = new BoardService('/test/issue-boards/board', '', '1');
    gl.issueBoards.BoardsStore.create();

    issue = new ListIssue({
      title: 'Testing',
      iid: 1,
      confidential: false,
      labels: [{
        id: 1,
        title: 'test',
        color: 'red',
        description: 'testing'
      }],
      assignees: [],
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

  it('sets position to infinity if no position is stored', () => {
    expect(issue.position).toBe(Infinity);
  });

  it('sets position', () => {
    const relativePositionIssue = new ListIssue({
      title: 'Testing',
      iid: 1,
      confidential: false,
      relative_position: 1,
      labels: [],
      assignees: [],
    });

    expect(relativePositionIssue.position).toBe(1);
  });
});
