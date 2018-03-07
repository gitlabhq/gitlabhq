/* eslint-disable comma-dangle, one-var, no-unused-vars */
/* global BoardService */
/* global ListIssue */

import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import Cookies from 'js-cookie';

import '~/vue_shared/models/label';
import '~/boards/models/issue';
import '~/boards/models/list';
import '~/boards/models/assignee';
import '~/boards/services/board_service';
import '~/boards/stores/boards_store';
import { listObj, listObjDuplicate, boardsMockInterceptor, mockBoardService } from './mock_data';

describe('Store', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onAny().reply(boardsMockInterceptor);
    gl.boardService = mockBoardService();
    gl.issueBoards.BoardsStore.create();

    spyOn(gl.boardService, 'moveIssue').and.callFake(() => new Promise((resolve) => {
      resolve();
    }));

    Cookies.set('issue_board_welcome_hidden', 'false', {
      expires: 365 * 10,
      path: ''
    });
  });

  afterEach(() => {
    mock.restore();
  });

  it('starts with a blank state', () => {
    expect(gl.issueBoards.BoardsStore.state.lists.length).toBe(0);
  });

  describe('lists', () => {
    it('creates new list without persisting to DB', () => {
      gl.issueBoards.BoardsStore.addList(listObj);

      expect(gl.issueBoards.BoardsStore.state.lists.length).toBe(1);
    });

    it('finds list by ID', () => {
      gl.issueBoards.BoardsStore.addList(listObj);
      const list = gl.issueBoards.BoardsStore.findList('id', listObj.id);

      expect(list.id).toBe(listObj.id);
    });

    it('finds list by type', () => {
      gl.issueBoards.BoardsStore.addList(listObj);
      const list = gl.issueBoards.BoardsStore.findList('type', 'label');

      expect(list).toBeDefined();
    });

    it('gets issue when new list added', (done) => {
      gl.issueBoards.BoardsStore.addList(listObj);
      const list = gl.issueBoards.BoardsStore.findList('id', listObj.id);

      expect(gl.issueBoards.BoardsStore.state.lists.length).toBe(1);

      setTimeout(() => {
        expect(list.issues.length).toBe(1);
        expect(list.issues[0].id).toBe(1);
        done();
      }, 0);
    });

    it('persists new list', (done) => {
      gl.issueBoards.BoardsStore.new({
        title: 'Test',
        list_type: 'label',
        label: {
          id: 1,
          title: 'Testing',
          color: 'red',
          description: 'testing;'
        }
      });
      expect(gl.issueBoards.BoardsStore.state.lists.length).toBe(1);

      setTimeout(() => {
        const list = gl.issueBoards.BoardsStore.findList('id', listObj.id);
        expect(list).toBeDefined();
        expect(list.id).toBe(listObj.id);
        expect(list.position).toBe(0);
        done();
      }, 0);
    });

    it('check for blank state adding', () => {
      expect(gl.issueBoards.BoardsStore.shouldAddBlankState()).toBe(true);
    });

    it('check for blank state not adding', () => {
      gl.issueBoards.BoardsStore.addList(listObj);
      expect(gl.issueBoards.BoardsStore.shouldAddBlankState()).toBe(false);
    });

    it('check for blank state adding when closed list exist', () => {
      gl.issueBoards.BoardsStore.addList({
        list_type: 'closed'
      });

      expect(gl.issueBoards.BoardsStore.shouldAddBlankState()).toBe(true);
    });

    it('adds the blank state', () => {
      gl.issueBoards.BoardsStore.addBlankState();

      const list = gl.issueBoards.BoardsStore.findList('type', 'blank', 'blank');
      expect(list).toBeDefined();
    });

    it('removes list from state', () => {
      gl.issueBoards.BoardsStore.addList(listObj);

      expect(gl.issueBoards.BoardsStore.state.lists.length).toBe(1);

      gl.issueBoards.BoardsStore.removeList(listObj.id, 'label');

      expect(gl.issueBoards.BoardsStore.state.lists.length).toBe(0);
    });

    it('moves the position of lists', () => {
      const listOne = gl.issueBoards.BoardsStore.addList(listObj);
      const listTwo = gl.issueBoards.BoardsStore.addList(listObjDuplicate);

      expect(gl.issueBoards.BoardsStore.state.lists.length).toBe(2);

      gl.issueBoards.BoardsStore.moveList(listOne, [listObjDuplicate.id, listObj.id]);

      expect(listOne.position).toBe(1);
    });

    it('moves an issue from one list to another', (done) => {
      const listOne = gl.issueBoards.BoardsStore.addList(listObj);
      const listTwo = gl.issueBoards.BoardsStore.addList(listObjDuplicate);

      expect(gl.issueBoards.BoardsStore.state.lists.length).toBe(2);

      setTimeout(() => {
        expect(listOne.issues.length).toBe(1);
        expect(listTwo.issues.length).toBe(1);

        gl.issueBoards.BoardsStore.moveIssueToList(listOne, listTwo, listOne.findIssue(1));

        expect(listOne.issues.length).toBe(0);
        expect(listTwo.issues.length).toBe(1);

        done();
      }, 0);
    });

    it('moves issue to top of another list', (done) => {
      const listOne = gl.issueBoards.BoardsStore.addList(listObj);
      const listTwo = gl.issueBoards.BoardsStore.addList(listObjDuplicate);

      expect(gl.issueBoards.BoardsStore.state.lists.length).toBe(2);

      setTimeout(() => {
        listOne.issues[0].id = 2;

        expect(listOne.issues.length).toBe(1);
        expect(listTwo.issues.length).toBe(1);

        gl.issueBoards.BoardsStore.moveIssueToList(listOne, listTwo, listOne.findIssue(2), 0);

        expect(listOne.issues.length).toBe(0);
        expect(listTwo.issues.length).toBe(2);
        expect(listTwo.issues[0].id).toBe(2);
        expect(gl.boardService.moveIssue).toHaveBeenCalledWith(2, listOne.id, listTwo.id, null, 1);

        done();
      }, 0);
    });

    it('moves issue to bottom of another list', (done) => {
      const listOne = gl.issueBoards.BoardsStore.addList(listObj);
      const listTwo = gl.issueBoards.BoardsStore.addList(listObjDuplicate);

      expect(gl.issueBoards.BoardsStore.state.lists.length).toBe(2);

      setTimeout(() => {
        listOne.issues[0].id = 2;

        expect(listOne.issues.length).toBe(1);
        expect(listTwo.issues.length).toBe(1);

        gl.issueBoards.BoardsStore.moveIssueToList(listOne, listTwo, listOne.findIssue(2), 1);

        expect(listOne.issues.length).toBe(0);
        expect(listTwo.issues.length).toBe(2);
        expect(listTwo.issues[1].id).toBe(2);
        expect(gl.boardService.moveIssue).toHaveBeenCalledWith(2, listOne.id, listTwo.id, 1, null);

        done();
      }, 0);
    });

    it('moves issue in list', (done) => {
      const issue = new ListIssue({
        title: 'Testing',
        id: 2,
        iid: 2,
        confidential: false,
        labels: [],
        assignees: [],
      });
      const list = gl.issueBoards.BoardsStore.addList(listObj);

      setTimeout(() => {
        list.addIssue(issue);

        expect(list.issues.length).toBe(2);

        gl.issueBoards.BoardsStore.moveIssueInList(list, issue, 0, 1, [1, 2]);

        expect(list.issues[0].id).toBe(2);
        expect(gl.boardService.moveIssue).toHaveBeenCalledWith(2, null, null, 1, null);

        done();
      });
    });
  });
});
