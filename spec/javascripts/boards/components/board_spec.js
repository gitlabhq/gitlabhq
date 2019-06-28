import Vue from 'vue';
import Board from '~/boards/components/board';
import List from '~/boards/models/list';
import { mockBoardService } from '../mock_data';

describe('Board component', () => {
  let vm;
  let el;

  beforeEach(done => {
    loadFixtures('boards/show.html');

    el = document.createElement('div');
    document.body.appendChild(el);

    gl.boardService = mockBoardService({
      boardsEndpoint: '/',
      listsEndpoint: '/',
      bulkUpdatePath: '/',
      boardId: 1,
    });

    vm = new Board({
      propsData: {
        boardId: '1',
        disabled: false,
        issueLinkBase: '/',
        rootPath: '/',
        list: new List({
          id: 1,
          position: 0,
          title: 'test',
          list_type: 'backlog',
        }),
      },
    }).$mount(el);

    Vue.nextTick(done);
  });

  afterEach(() => {
    vm.$destroy();

    // remove the component from the DOM
    document.querySelector('.board').remove();

    localStorage.removeItem(`boards.${vm.boardId}.${vm.list.type}.expanded`);
  });

  it('board is expandable when list type is backlog', () => {
    expect(vm.$el.classList.contains('is-expandable')).toBe(true);
  });

  it('board is expandable when list type is closed', () => {
    expect(new List({ id: 1, list_type: 'closed' }).isExpandable).toBe(true);
  });

  it('board is expandable when list type is label', () => {
    expect(new List({ id: 1, list_type: 'closed' }).isExpandable).toBe(true);
  });

  it('board is not expandable when list type is blank', () => {
    expect(new List({ id: 1, list_type: 'blank' }).isExpandable).toBe(false);
  });

  it('does not collapse when clicking header', done => {
    vm.list.isExpanded = true;
    vm.$el.querySelector('.board-header').click();

    Vue.nextTick(() => {
      expect(vm.$el.classList.contains('is-collapsed')).toBe(false);

      done();
    });
  });

  it('collapses when clicking the collapse icon', done => {
    vm.list.isExpanded = true;

    Vue.nextTick()
      .then(() => {
        vm.$el.querySelector('.board-title-caret').click();
      })
      .then(() => {
        expect(vm.$el.classList.contains('is-collapsed')).toBe(true);
        done();
      })
      .catch(done.fail);
  });

  it('expands when clicking the expand icon', done => {
    vm.list.isExpanded = false;

    Vue.nextTick()
      .then(() => {
        vm.$el.querySelector('.board-title-caret').click();
      })
      .then(() => {
        expect(vm.$el.classList.contains('is-collapsed')).toBe(false);
        done();
      })
      .catch(done.fail);
  });

  it('is expanded when created', () => {
    expect(vm.list.isExpanded).toBe(true);
    expect(vm.$el.classList.contains('is-collapsed')).toBe(false);
  });

  it('does render add issue button', () => {
    expect(vm.$el.querySelector('.issue-count-badge-add-button')).not.toBeNull();
  });

  it('does not render add issue button when list type is blank', done => {
    vm.list.type = 'blank';

    Vue.nextTick(() => {
      expect(vm.$el.querySelector('.issue-count-badge-add-button')).toBeNull();

      done();
    });
  });
});
