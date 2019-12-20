import $ from 'jquery';
import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import DeprecatedModal from '~/vue_shared/components/deprecated_modal.vue';

const modalComponent = Vue.extend(DeprecatedModal);

describe('DeprecatedModal', () => {
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('props', () => {
    describe('without primaryButtonLabel', () => {
      beforeEach(() => {
        vm = mountComponent(modalComponent, {
          primaryButtonLabel: null,
        });
      });

      it('does not render a primary button', () => {
        expect(vm.$el.querySelector('.js-primary-button')).toBeNull();
      });
    });

    describe('with id', () => {
      describe('does not render a primary button', () => {
        beforeEach(() => {
          vm = mountComponent(modalComponent, {
            id: 'my-modal',
          });
        });

        it('assigns the id to the modal', () => {
          expect(vm.$el.querySelector('#my-modal.modal')).not.toBeNull();
        });

        it('does not show the modal immediately', () => {
          expect(vm.$el.querySelector('#my-modal.modal')).not.toHaveClass('show');
        });

        it('does not show a backdrop', () => {
          expect(vm.$el.querySelector('modal-backdrop')).toBeNull();
        });
      });
    });

    it('works with data-toggle="modal"', done => {
      setFixtures(`
        <button id="modal-button" data-toggle="modal" data-target="#my-modal"></button>
        <div id="modal-container"></div>
      `);

      const modalContainer = document.getElementById('modal-container');
      const modalButton = document.getElementById('modal-button');
      vm = mountComponent(
        modalComponent,
        {
          id: 'my-modal',
        },
        modalContainer,
      );
      const modalElement = vm.$el.querySelector('#my-modal');
      $(modalElement).on('shown.bs.modal', () => done());

      modalButton.click();
    });
  });
});
