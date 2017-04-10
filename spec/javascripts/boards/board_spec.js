/* global BoardService */
/* global boardsMockInterceptor */
/* global List */
/* global listObj */
import Vue from 'vue';
import VueResource from 'vue-resource';
import board from '~/boards/components/board';
import '~/boards/models/list';
import '~/boards/stores/boards_store';
import './mock_data';

Vue.use(VueResource);

describe('Board component', () => {
  let vm;

  beforeEach((done) => {
    gl.boardService = new BoardService('/test/issue-boards/board', '', '1');
    gl.issueBoards.BoardsStore.create();

    Vue.http.interceptors.push(boardsMockInterceptor);

    const el = document.createElement('div');
    const BoardComponent = Vue.extend(board);
    const list = new List(listObj);

    document.body.appendChild(el);

    vm = new BoardComponent({
      el,
      propsData: {
        list,
        disabled: false,
        issueLinkBase: '/issue',
        rootPath: '/',
        store: gl.issueBoards.BoardsStore,
      },
    }).$mount();

    Vue.nextTick(done);
  });

  afterEach(() => {
    Vue.http.interceptors = _.without(Vue.http.interceptors, boardsMockInterceptor);
  });

  it('allows board to be dragged', () => {
    expect(
      vm.$el.classList.contains('is-draggable'),
    ).toBeTruthy();
  });

  it('does not allow board to be dragged when list is preset', (done) => {
    vm.list.preset = true;

    Vue.nextTick(() => {
      expect(
        vm.$el.classList.contains('is-draggable'),
      ).toBeFalsy();

      done();
    });
  });

  describe('delete button', () => {
    it('does not render delete button when permissions are incorrect', () => {
      expect(
        vm.$el.querySelector('.board-delete'),
      ).toBeNull();
    });

    it('does not render delete button when list is preset', (done) => {
      vm.canAdminList = true;
      vm.list.preset = true;

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelector('.board-delete'),
        ).toBeNull();

        done();
      });
    });

    it('renders delete button when permissions are correct', (done) => {
      vm.canAdminList = true;

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelector('.board-delete'),
        ).not.toBeNull();

        done();
      });
    });
  });

  describe('new issue button', () => {
    it('does not render new issue button when permissions are incorrect', () => {
      expect(
        vm.$el.querySelector('.board-title .btn'),
      ).toBeNull();
    });

    it('does not render new issue button when list is \'closed\'', (done) => {
      vm.canAdminIssue = true;
      vm.list.type = 'closed';

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelector('.board-title .btn'),
        ).toBeNull();

        done();
      });
    });

    it('renders new issue button when permissions are correct', (done) => {
      vm.canAdminIssue = true;

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelector('.board-title .btn'),
        ).not.toBeNull();

        done();
      });
    });

    it('sets has-btn class', () => {
      expect(
        vm.$el.querySelector('.has-btn'),
      ).not.toBeNull();
    });

    it('shows new issue form', (done) => {
      vm.canAdminIssue = true;

      Vue.nextTick(() => {
        vm.$el.querySelector('.board-title .btn').click();

        Vue.nextTick(() => {
          expect(
            vm.$el.querySelector('.board-new-issue-form'),
          ).not.toBeNull();

          done();
        });
      });
    });
  });

  it('renders issue size', (done) => {
    setTimeout(() => {
      expect(
        vm.$el.querySelector('.board-issue-count'),
      ).not.toBeNull();

      expect(
        vm.$el.querySelector('.board-issue-count').textContent.trim(),
      ).toBe('1');

      done();
    }, 0);
  });

  it('renders blank state', (done) => {
    vm.canAdminList = true;
    vm.list.id = 'blank';

    Vue.nextTick(() => {
      expect(
        vm.$el.querySelector('.board-blank-state'),
      ).not.toBeNull();

      done();
    });
  });
});
