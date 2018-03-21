/* eslint-disable comma-dangle */
/* global BoardService */
/* global List */
/* global ListIssue */

import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import _ from 'underscore';
import '~/vue_shared/models/label';
import '~/boards/models/issue';
import '~/boards/models/list';
import '~/boards/models/assignee';
import '~/boards/services/board_service';
import '~/boards/stores/boards_store';
import { listObj, listObjDuplicate, boardsMockInterceptor, mockBoardService } from './mock_data';

describe('List model', () => {
  let list;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onAny().reply(boardsMockInterceptor);
    gl.boardService = mockBoardService({
      bulkUpdatePath: '/test/issue-boards/board/1/lists',
    });
    gl.issueBoards.BoardsStore.create();

    list = new List(listObj);
  });

  afterEach(() => {
    mock.restore();
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
        id: _.random(10000),
        title: 'test',
        color: 'red'
      }
    });
    list.save();

    setTimeout(() => {
      expect(list.id).toBe(listObj.id);
      expect(list.type).toBe('label');
      expect(list.position).toBe(0);
      done();
    }, 0);
  });

  it('destroys the list', (done) => {
    gl.issueBoards.BoardsStore.addList(listObj);
    list = gl.issueBoards.BoardsStore.findList('id', listObj.id);
    expect(gl.issueBoards.BoardsStore.state.lists.length).toBe(1);
    list.destroy();

    setTimeout(() => {
      expect(gl.issueBoards.BoardsStore.state.lists.length).toBe(0);
      done();
    }, 0);
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

  it('sends service request to update issue label', () => {
    const listDup = new List(listObjDuplicate);
    const issue = new ListIssue({
      title: 'Testing',
      id: _.random(10000),
      iid: _.random(10000),
      confidential: false,
      labels: [list.label, listDup.label],
      assignees: [],
    });

    list.issues.push(issue);
    listDup.issues.push(issue);

    spyOn(gl.boardService, 'moveIssue').and.callThrough();

    listDup.updateIssueLabel(issue, list);

    expect(gl.boardService.moveIssue)
      .toHaveBeenCalledWith(issue.id, list.id, listDup.id, undefined, undefined);
  });

  describe('page number', () => {
    beforeEach(() => {
      spyOn(list, 'getIssues');
    });

    it('increase page number if current issue count is more than the page size', () => {
      for (let i = 0; i < 30; i += 1) {
        list.issues.push(new ListIssue({
          title: 'Testing',
          id: _.random(10000) + i,
          iid: _.random(10000) + i,
          confidential: false,
          labels: [list.label],
          assignees: [],
        }));
      }
      list.issuesSize = 50;

      expect(list.issues.length).toBe(30);

      list.nextPage();

      expect(list.page).toBe(2);
      expect(list.getIssues).toHaveBeenCalled();
    });

    it('does not increase page number if issue count is less than the page size', () => {
      list.issues.push(new ListIssue({
        title: 'Testing',
        id: _.random(10000),
        confidential: false,
        labels: [list.label],
        assignees: [],
      }));
      list.issuesSize = 2;

      list.nextPage();

      expect(list.page).toBe(1);
      expect(list.getIssues).toHaveBeenCalled();
    });
  });

  describe('newIssue', () => {
    beforeEach(() => {
      spyOn(gl.boardService, 'newIssue').and.returnValue(Promise.resolve({
        data: {
          id: 42,
        },
      }));
    });

    it('adds new issue to top of list', (done) => {
      list.issues.push(new ListIssue({
        title: 'Testing',
        id: _.random(10000),
        confidential: false,
        labels: [list.label],
        assignees: [],
      }));
      const dummyIssue = new ListIssue({
        title: 'new issue',
        id: _.random(10000),
        confidential: false,
        labels: [list.label],
        assignees: [],
      });

      list.newIssue(dummyIssue)
        .then(() => {
          expect(list.issues.length).toBe(2);
          expect(list.issues[0]).toBe(dummyIssue);
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
