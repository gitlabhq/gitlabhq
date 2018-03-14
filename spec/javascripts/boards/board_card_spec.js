/* global List */
/* global ListAssignee */
/* global ListLabel */
/* global BoardService */

import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import '~/boards/models/assignee';

import eventHub from '~/boards/eventhub';
import '~/vue_shared/models/label';
import '~/boards/models/list';
import '~/boards/stores/boards_store';
import boardCard from '~/boards/components/board_card.vue';
import { listObj, boardsMockInterceptor, mockBoardService } from './mock_data';

describe('Board card', () => {
  let vm;
  let mock;

  beforeEach((done) => {
    mock = new MockAdapter(axios);
    mock.onAny().reply(boardsMockInterceptor);

    gl.boardService = mockBoardService();
    gl.issueBoards.BoardsStore.create();
    gl.issueBoards.BoardsStore.detail.issue = {};

    const BoardCardComp = Vue.extend(boardCard);
    const list = new List(listObj);
    const label1 = new ListLabel({
      id: 3,
      title: 'testing 123',
      color: 'blue',
      text_color: 'white',
      description: 'test',
    });

    setTimeout(() => {
      list.issues[0].labels.push(label1);

      vm = new BoardCardComp({
        propsData: {
          list,
          issue: list.issues[0],
          issueLinkBase: '/',
          disabled: false,
          index: 0,
          rootPath: '/',
        },
      }).$mount();
      done();
    }, 0);
  });

  afterEach(() => {
    mock.restore();
  });

  it('returns false when detailIssue is empty', () => {
    expect(vm.issueDetailVisible).toBe(false);
  });

  it('returns true when detailIssue is equal to card issue', () => {
    gl.issueBoards.BoardsStore.detail.issue = vm.issue;

    expect(vm.issueDetailVisible).toBe(true);
  });

  it('adds user-can-drag class if not disabled', () => {
    expect(vm.$el.classList.contains('user-can-drag')).toBe(true);
  });

  it('does not add user-can-drag class disabled', (done) => {
    vm.disabled = true;

    setTimeout(() => {
      expect(vm.$el.classList.contains('user-can-drag')).toBe(false);
      done();
    }, 0);
  });

  it('does not add disabled class', () => {
    expect(vm.$el.classList.contains('is-disabled')).toBe(false);
  });

  it('adds disabled class is disabled is true', (done) => {
    vm.disabled = true;

    setTimeout(() => {
      expect(vm.$el.classList.contains('is-disabled')).toBe(true);
      done();
    }, 0);
  });

  describe('mouse events', () => {
    const triggerEvent = (eventName, el = vm.$el) => {
      const event = document.createEvent('MouseEvents');
      event.initMouseEvent(eventName, true, true, window, 1, 0, 0, 0, 0, false, false,
                           false, false, 0, null);

      el.dispatchEvent(event);
    };

    it('sets showDetail to true on mousedown', () => {
      triggerEvent('mousedown');

      expect(vm.showDetail).toBe(true);
    });

    it('sets showDetail to false on mousemove', () => {
      triggerEvent('mousedown');

      expect(vm.showDetail).toBe(true);

      triggerEvent('mousemove');

      expect(vm.showDetail).toBe(false);
    });

    it('does not set detail issue if showDetail is false', () => {
      expect(gl.issueBoards.BoardsStore.detail.issue).toEqual({});
    });

    it('does not set detail issue if link is clicked', () => {
      triggerEvent('mouseup', vm.$el.querySelector('a'));

      expect(gl.issueBoards.BoardsStore.detail.issue).toEqual({});
    });

    it('does not set detail issue if button is clicked', () => {
      triggerEvent('mouseup', vm.$el.querySelector('button'));

      expect(gl.issueBoards.BoardsStore.detail.issue).toEqual({});
    });

    it('does not set detail issue if img is clicked', (done) => {
      vm.issue.assignees = [new ListAssignee({
        id: 1,
        name: 'testing 123',
        username: 'test',
        avatar: 'test_image',
      })];

      Vue.nextTick(() => {
        triggerEvent('mouseup', vm.$el.querySelector('img'));

        expect(gl.issueBoards.BoardsStore.detail.issue).toEqual({});

        done();
      });
    });

    it('does not set detail issue if showDetail is false after mouseup', () => {
      triggerEvent('mouseup');

      expect(gl.issueBoards.BoardsStore.detail.issue).toEqual({});
    });

    it('sets detail issue to card issue on mouse up', () => {
      spyOn(eventHub, '$emit');

      triggerEvent('mousedown');
      triggerEvent('mouseup');

      expect(eventHub.$emit).toHaveBeenCalledWith('newDetailIssue', vm.issue);
      expect(gl.issueBoards.BoardsStore.detail.list).toEqual(vm.list);
    });

    it('adds active class if detail issue is set', (done) => {
      vm.detailIssue.issue = vm.issue;

      Vue.nextTick()
        .then(() => {
          expect(vm.$el.classList.contains('is-active')).toBe(true);
        })
        .then(done)
        .catch(done.fail);
    });

    it('resets detail issue to empty if already set', () => {
      spyOn(eventHub, '$emit');

      gl.issueBoards.BoardsStore.detail.issue = vm.issue;

      triggerEvent('mousedown');
      triggerEvent('mouseup');

      expect(eventHub.$emit).toHaveBeenCalledWith('clearDetailIssue');
    });
  });
});
