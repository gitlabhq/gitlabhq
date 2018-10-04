import Vue from 'vue';

import SidebarTodos from '~/sidebar/components/todo_toggle/todo.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

const createComponent = ({
  issuableId = 1,
  issuableType = 'epic',
  isTodo,
  isActionActive,
  collapsed,
}) => {
  const Component = Vue.extend(SidebarTodos);

  return mountComponent(Component, {
    issuableId,
    issuableType,
    isTodo,
    isActionActive,
    collapsed,
  });
};

describe('SidebarTodo', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent({});
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('buttonClasses', () => {
      it('returns todo button classes for when `collapsed` prop is `false`', () => {
        expect(vm.buttonClasses).toBe('btn btn-default btn-todo issuable-header-btn float-right');
      });

      it('returns todo button classes for when `collapsed` prop is `true`', done => {
        vm.collapsed = true;
        Vue.nextTick()
          .then(() => {
            expect(vm.buttonClasses).toBe('btn-blank btn-todo sidebar-collapsed-icon dont-change-state');
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('buttonLabel', () => {
      it('returns todo button text for marking todo as done when `isTodo` prop is `true`', () => {
        expect(vm.buttonLabel).toBe('Mark todo as done');
      });

      it('returns todo button text for add todo when `isTodo` prop is `false`', done => {
        vm.isTodo = false;
        Vue.nextTick()
          .then(() => {
            expect(vm.buttonLabel).toBe('Add todo');
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('collapsedButtonIconClasses', () => {
      it('returns collapsed button icon class when `isTodo` prop is `true`', () => {
        expect(vm.collapsedButtonIconClasses).toBe('todo-undone');
      });

      it('returns empty string when `isTodo` prop is `false`', done => {
        vm.isTodo = false;
        Vue.nextTick()
          .then(() => {
            expect(vm.collapsedButtonIconClasses).toBe('');
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('collapsedButtonIcon', () => {
      it('returns button icon name when `isTodo` prop is `true`', () => {
        expect(vm.collapsedButtonIcon).toBe('todo-done');
      });

      it('returns button icon name when `isTodo` prop is `false`', done => {
        vm.isTodo = false;
        Vue.nextTick()
          .then(() => {
            expect(vm.collapsedButtonIcon).toBe('todo-add');
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('methods', () => {
    describe('handleButtonClick', () => {
      it('emits `toggleTodo` event on component', () => {
        spyOn(vm, '$emit');
        vm.handleButtonClick();
        expect(vm.$emit).toHaveBeenCalledWith('toggleTodo');
      });
    });
  });

  describe('template', () => {
    it('renders component container element', () => {
      const dataAttributes = {
        issuableId: '1',
        issuableType: 'epic',
        originalTitle: 'Mark todo as done',
        placement: 'left',
        container: 'body',
        boundary: 'viewport',
      };
      expect(vm.$el.nodeName).toBe('BUTTON');

      const elDataAttrs = vm.$el.dataset;
      Object.keys(elDataAttrs).forEach((attr) => {
        expect(elDataAttrs[attr]).toBe(dataAttributes[attr]);
      });
    });

    it('renders button label element when `collapsed` prop is `false`', () => {
      const buttonLabelEl = vm.$el.querySelector('span.issuable-todo-inner');
      expect(buttonLabelEl).not.toBeNull();
      expect(buttonLabelEl.innerText.trim()).toBe('Mark todo as done');
    });

    it('renders button icon when `collapsed` prop is `true`', done => {
      vm.collapsed = true;
      Vue.nextTick()
        .then(() => {
          const buttonIconEl = vm.$el.querySelector('svg');
          expect(buttonIconEl).not.toBeNull();
          expect(buttonIconEl.querySelector('use').getAttribute('xlink:href')).toContain('todo-done');
        })
        .then(done)
        .catch(done.fail);
    });

    it('renders loading icon when `isActionActive` prop is true', done => {
      vm.isActionActive = true;
      Vue.nextTick()
        .then(() => {
          const loadingEl = vm.$el.querySelector('span.loading-container');
          expect(loadingEl).not.toBeNull();
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
