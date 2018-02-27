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
