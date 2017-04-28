/* eslint-disable comma-dangle */
/* global boardsMockInterceptor */
/* global BoardService */
/* global List */
/* global ListIssue */
/* global listObj */
/* global listObjDuplicate */

import Vue from 'vue';

import '~/lib/utils/url_utility';
import '~/boards/models/issue';
import '~/boards/models/label';
import '~/boards/models/list';
import '~/boards/models/assignee';
import '~/boards/services/board_service';
import '~/boards/stores/boards_store';
import './mock_data';

describe('List model', () => {
  let list;

  beforeEach(() => {
    Vue.http.interceptors.push(boardsMockInterceptor);
    gl.boardService = new BoardService('/test/issue-boards/board', '', '1');
    gl.issueBoards.BoardsStore.create();

    list = new List(listObj);
  });

  afterEach(() => {
    Vue.http.interceptors = _.without(Vue.http.interceptors, boardsMockInterceptor);
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
    gl.issueBoards.BoardsStore.addList(listObj);
    list = gl.issueBoards.BoardsStore.findList('id', 1);
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
      iid: 1,
      confidential: false,
      labels: [list.label, listDup.label],
      assignees: [],
    });

    list.issues.push(issue);
    listDup.issues.push(issue);

    spyOn(gl.boardService, 'moveIssue').and.callThrough();

    listDup.updateIssueLabel(list, issue);

    expect(gl.boardService.moveIssue)
      .toHaveBeenCalledWith(issue.id, list.id, listDup.id, undefined, undefined);
  });
});
