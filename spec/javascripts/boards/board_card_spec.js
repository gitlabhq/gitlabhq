/* global Vue */
/* global List */
/* global ListLabel */
/* global listObj */
/* global boardsMockInterceptor */
/* global BoardService */

require('~/boards/models/list');
require('~/boards/models/label');
require('~/boards/stores/boards_store');
const boardCard = require('~/boards/components/board_card');
require('./mock_data');

describe('Issue card', () => {
  let vm;

  beforeEach((done) => {
    Vue.http.interceptors.push(boardsMockInterceptor);

    gl.boardService = new BoardService('/test/issue-boards/board', '', '1');
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
    Vue.http.interceptors = _.without(Vue.http.interceptors, boardsMockInterceptor);
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

    it('does not set detail issue if showDetail is false after mouseup', () => {
      triggerEvent('mouseup');

      expect(gl.issueBoards.BoardsStore.detail.issue).toEqual({});
    });

    it('sets detail issue to card issue on mouse up', () => {
      triggerEvent('mousedown');
      triggerEvent('mouseup');

      expect(gl.issueBoards.BoardsStore.detail.issue).toEqual(vm.issue);
      expect(gl.issueBoards.BoardsStore.detail.list).toEqual(vm.list);
    });

    it('adds active class if detail issue is set', (done) => {
      triggerEvent('mousedown');
      triggerEvent('mouseup');

      setTimeout(() => {
        expect(vm.$el.classList.contains('is-active')).toBe(true);
        done();
      }, 0);
    });

    it('resets detail issue to empty if already set', () => {
      triggerEvent('mousedown');
      triggerEvent('mouseup');

      expect(gl.issueBoards.BoardsStore.detail.issue).toEqual(vm.issue);

      triggerEvent('mousedown');
      triggerEvent('mouseup');

      expect(gl.issueBoards.BoardsStore.detail.issue).toEqual({});
    });
  });
});
