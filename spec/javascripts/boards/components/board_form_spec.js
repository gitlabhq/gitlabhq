import $ from 'jquery';
import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import boardsStore from '~/boards/stores/boards_store';
import boardForm from '~/boards/components/board_form.vue';

describe('board_form.vue', () => {
  const props = {
    canAdminBoard: false,
    labelsPath: `${gl.TEST_HOST}/labels/path`,
    milestonePath: `${gl.TEST_HOST}/milestone/path`,
  };
  let vm;

  beforeEach(() => {
    spyOn($, 'ajax');
    boardsStore.state.currentPage = 'edit';
    const Component = Vue.extend(boardForm);
    vm = mountComponent(Component, props);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('methods', () => {
    describe('cancel', () => {
      it('resets currentPage', done => {
        vm.cancel();

        Vue.nextTick()
          .then(() => {
            expect(boardsStore.state.currentPage).toBe('');
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('buttons', () => {
    it('cancel button triggers cancel()', done => {
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
