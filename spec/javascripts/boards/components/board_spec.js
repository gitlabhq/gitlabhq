import Vue from 'vue';
import Board from '~/boards/components/board';
import List from '~/boards/models/list';

describe('Board component', () => {
  let vm;

  const createComponent = ({ gon = {}, collapsed = false, listType = 'backlog' } = {}) => {
    if (Object.prototype.hasOwnProperty.call(gon, 'current_user_id')) {
      window.gon = gon;
    } else {
      window.gon = {};
    }
    const el = document.createElement('div');
    document.body.appendChild(el);

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
          list_type: listType,
          collapsed,
        }),
      },
    }).$mount(el);
  };

  const setUpTests = (done, opts = {}) => {
    loadFixtures('boards/show.html');

    createComponent(opts);

    Vue.nextTick(done);
  };

  const cleanUpTests = spy => {
    if (spy) {
      spy.calls.reset();
    }

    vm.$destroy();

    // remove the component from the DOM
    document.querySelector('.board').remove();

    localStorage.removeItem(`${vm.uniqueKey}.expanded`);
  };

  describe('List', () => {
    it('board is expandable when list type is closed', () => {
      expect(new List({ id: 1, list_type: 'closed' }).isExpandable).toBe(true);
    });

    it('board is expandable when list type is label', () => {
      expect(new List({ id: 1, list_type: 'closed' }).isExpandable).toBe(true);
    });

    it('board is not expandable when list type is blank', () => {
      expect(new List({ id: 1, list_type: 'blank' }).isExpandable).toBe(false);
    });
  });

  describe('when clicking the header', () => {
    beforeEach(done => {
      setUpTests(done);
    });

    afterEach(() => {
      cleanUpTests();
    });

    it('does not collapse', done => {
      vm.list.isExpanded = true;
      vm.$el.querySelector('.board-header').click();

      Vue.nextTick()
        .then(() => {
          expect(vm.$el.classList.contains('is-collapsed')).toBe(false);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('when clicking the collapse icon', () => {
    beforeEach(done => {
      setUpTests(done);
    });

    afterEach(() => {
      cleanUpTests();
    });

    it('collapses', done => {
      Vue.nextTick()
        .then(() => {
          vm.$el.querySelector('.board-title-caret').click();
        })
        .then(() => {
          expect(vm.$el.classList.contains('is-collapsed')).toBe(true);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('when clicking the expand icon', () => {
    beforeEach(done => {
      setUpTests(done);
    });

    afterEach(() => {
      cleanUpTests();
    });

    it('expands', done => {
      vm.list.isExpanded = false;

      Vue.nextTick()
        .then(() => {
          vm.$el.querySelector('.board-title-caret').click();
        })
        .then(() => {
          expect(vm.$el.classList.contains('is-collapsed')).toBe(false);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('when collapsed is false', () => {
    beforeEach(done => {
      setUpTests(done);
    });

    afterEach(() => {
      cleanUpTests();
    });

    it('is expanded when collapsed is false', () => {
      expect(vm.list.isExpanded).toBe(true);
      expect(vm.$el.classList.contains('is-collapsed')).toBe(false);
    });
  });

  describe('when list type is blank', () => {
    beforeEach(done => {
      setUpTests(done, { listType: 'blank' });
    });

    afterEach(() => {
      cleanUpTests();
    });

    it('does not render add issue button when list type is blank', done => {
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.issue-count-badge-add-button')).toBeNull();

        done();
      });
    });
  });

  describe('when list type is backlog', () => {
    beforeEach(done => {
      setUpTests(done);
    });

    afterEach(() => {
      cleanUpTests();
    });

    it('board is expandable', () => {
      expect(vm.$el.classList.contains('is-expandable')).toBe(true);
    });
  });

  describe('when logged in', () => {
    let spy;

    beforeEach(done => {
      spy = spyOn(List.prototype, 'update');
      setUpTests(done, { gon: { current_user_id: 1 } });
    });

    afterEach(() => {
      cleanUpTests(spy);
    });

    it('calls list update', done => {
      Vue.nextTick()
        .then(() => {
          vm.$el.querySelector('.board-title-caret').click();
        })
        .then(() => {
          expect(vm.list.update).toHaveBeenCalledTimes(1);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('when logged out', () => {
    let spy;
    beforeEach(done => {
      spy = spyOn(List.prototype, 'update');
      setUpTests(done, { collapsed: false });
    });

    afterEach(() => {
      cleanUpTests(spy);
    });

    // can only be one or the other cant toggle window.gon.current_user_id states.
    it('clicking on the caret does not call list update', done => {
      Vue.nextTick()
        .then(() => {
          vm.$el.querySelector('.board-title-caret').click();
        })
        .then(() => {
          expect(vm.list.update).toHaveBeenCalledTimes(0);
        })
        .then(done)
        .catch(done.fail);
    });

    it('sets expanded to be the opposite of its value when toggleExpanded is called', done => {
      const expanded = true;
      vm.list.isExpanded = expanded;
      vm.toggleExpanded();

      Vue.nextTick()
        .then(() => {
          expect(vm.list.isExpanded).toBe(!expanded);
          expect(localStorage.getItem(`${vm.uniqueKey}.expanded`)).toBe(String(!expanded));
        })
        .then(done)
        .catch(done.fail);
    });

    it('does render add issue button', () => {
      expect(vm.$el.querySelector('.issue-count-badge-add-button')).not.toBeNull();
    });
  });
});
