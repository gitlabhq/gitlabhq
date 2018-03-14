import $ from 'jquery';
import Vue from 'vue';

import boardForm from 'ee/boards/components/board_form.vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('board_form.vue', () => {
  const props = {
    canAdminBoard: false,
    labelsPath: `${gl.TEST_HOST}/labels/path`,
    milestonePath: `${gl.TEST_HOST}/milestone/path`,
  };
  let vm;

  beforeEach(() => {
    spyOn($, 'ajax');
    gl.issueBoards.BoardsStore.state.currentPage = 'edit';
    const Component = Vue.extend(boardForm);
    vm = mountComponent(Component, props);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('methods', () => {
    describe('handleLabelClick', () => {
      const label = {
        id: 1,
        title: 'Foo',
        color: ['#BADA55'],
        text_color: '#FFFFFF',
      };

      it('initializes `board.labels` as empty array when `label.isAny` is `true`', () => {
        const labelIsAny = { isAny: true };
        vm.handleLabelClick(labelIsAny);
        expect(Array.isArray(vm.board.labels)).toBe(true);
        expect(vm.board.labels.length).toBe(0);
      });

      it('adds provided `label` to board.labels', () => {
        vm.handleLabelClick(label);
        expect(vm.board.labels.length).toBe(1);
        expect(vm.board.labels[0].id).toBe(label.id);
        vm.handleLabelClick(label);
      });

      it('filters board.labels to exclude provided `label` if it is already present in `board.labels`', () => {
        const label2 = Object.assign({}, label, { id: 2 });
        vm.handleLabelClick(label);
        vm.handleLabelClick(label2);
        expect(vm.board.labels.length).toBe(1);
        expect(vm.board.labels[0].id).toBe(label2.id);
      });
    });

    describe('cancel', () => {
      it('resets currentPage', (done) => {
        vm.cancel();

        Vue.nextTick()
          .then(() => {
            expect(gl.issueBoards.BoardsStore.state.currentPage).toBe('');
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('buttons', () => {
    it('cancel button triggers cancel()', (done) => {
      spyOn(vm, 'cancel');

      Vue.nextTick()
        .then(() => {
          const cancelButton = vm.$el.querySelector('button[data-dismiss="modal"]');
          cancelButton.click();

          expect(vm.cancel).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
