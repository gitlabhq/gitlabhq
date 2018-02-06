import Vue from 'vue';
import '~/boards/services/board_service';
import '~/boards/components/board';
import '~/boards/models/list';
import { mockBoardService } from '../mock_data';

describe('Board component', () => {
  let vm;
  let el;

  beforeEach((done) => {
    loadFixtures('boards/show.html.raw');

    el = document.createElement('div');
    document.body.appendChild(el);

    gl.boardService = mockBoardService({
      boardsEndpoint: '/',
      listsEndpoint: '/',
      bulkUpdatePath: '/',
      boardId: 1,
    });

    vm = new gl.issueBoards.Board({
      propsData: {
        boardId: '1',
        disabled: false,
        issueLinkBase: '/',
        rootPath: '/',
        // eslint-disable-next-line no-undef
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
    expect(
      vm.$el.classList.contains('is-expandable'),
    ).toBe(true);
  });

  it('board is expandable when list type is closed', (done) => {
    vm.list.type = 'closed';

    Vue.nextTick(() => {
      expect(
        vm.$el.classList.contains('is-expandable'),
      ).toBe(true);

      done();
    });
  });

  it('board is not expandable when list type is label', (done) => {
    vm.list.type = 'label';
    vm.list.isExpandable = false;

    Vue.nextTick(() => {
      expect(
        vm.$el.classList.contains('is-expandable'),
      ).toBe(false);

      done();
    });
  });

  it('collapses when clicking header', (done) => {
    vm.$el.querySelector('.board-header').click();

    Vue.nextTick(() => {
      expect(
        vm.$el.classList.contains('is-collapsed'),
      ).toBe(true);

      done();
    });
  });

  it('created sets isExpanded to true from localStorage', (done) => {
    vm.$el.querySelector('.board-header').click();

    return Vue.nextTick()
      .then(() => {
        expect(
          vm.$el.classList.contains('is-collapsed'),
        ).toBe(true);

        // call created manually
        vm.$options.created[0].call(vm);

        return Vue.nextTick();
      })
      .then(() => {
        expect(
          vm.$el.classList.contains('is-collapsed'),
        ).toBe(true);

        done();
      });
  });
});
