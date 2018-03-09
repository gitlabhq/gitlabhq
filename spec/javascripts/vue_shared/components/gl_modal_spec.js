import $ from 'jquery';
import Vue from 'vue';
import GlModal from '~/vue_shared/components/gl_modal.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

const modalComponent = Vue.extend(GlModal);

describe('GlModal', () => {
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('props', () => {
    describe('with id', () => {
      const props = {
        id: 'my-modal',
      };

      beforeEach(() => {
        vm = mountComponent(modalComponent, props);
      });

      it('assigns the id to the modal', () => {
        expect(vm.$el.id).toBe(props.id);
      });
    });

    describe('without id', () => {
      beforeEach(() => {
        vm = mountComponent(modalComponent, { });
      });

      it('does not add an id attribute to the modal', () => {
        expect(vm.$el.hasAttribute('id')).toBe(false);
      });
    });

    describe('with headerTitleText', () => {
      const props = {
        headerTitleText: 'my title text',
      };

      beforeEach(() => {
        vm = mountComponent(modalComponent, props);
      });

      it('sets the modal title', () => {
        const modalTitle = vm.$el.querySelector('.modal-title');
        expect(modalTitle.innerHTML.trim()).toBe(props.headerTitleText);
      });
    });

    describe('with footerPrimaryButtonVariant', () => {
      const props = {
        footerPrimaryButtonVariant: 'danger',
      };

      beforeEach(() => {
        vm = mountComponent(modalComponent, props);
      });

      it('sets the primary button class', () => {
        const primaryButton = vm.$el.querySelector('.modal-footer button:last-of-type');
        expect(primaryButton).toHaveClass(`btn-${props.footerPrimaryButtonVariant}`);
      });
    });

    describe('with footerPrimaryButtonText', () => {
      const props = {
        footerPrimaryButtonText: 'my button text',
      };

      beforeEach(() => {
        vm = mountComponent(modalComponent, props);
      });

      it('sets the primary button text', () => {
        const primaryButton = vm.$el.querySelector('.modal-footer button:last-of-type');
        expect(primaryButton.innerHTML.trim()).toBe(props.footerPrimaryButtonText);
      });
    });
  });

  it('works with data-toggle="modal"', (done) => {
    setFixtures(`
      <button id="modal-button" data-toggle="modal" data-target="#my-modal"></button>
      <div id="modal-container"></div>
    `);

    const modalContainer = document.getElementById('modal-container');
    const modalButton = document.getElementById('modal-button');
    vm = mountComponent(modalComponent, {
      id: 'my-modal',
    }, modalContainer);
    $(vm.$el).on('shown.bs.modal', () => done());

    modalButton.click();
  });

  describe('methods', () => {
    const dummyEvent = 'not really an event';

    beforeEach(() => {
      vm = mountComponent(modalComponent, { });
      spyOn(vm, '$emit');
    });

    describe('emitCancel', () => {
      it('emits a cancel event', () => {
        vm.emitCancel(dummyEvent);

        expect(vm.$emit).toHaveBeenCalledWith('cancel', dummyEvent);
      });
    });

    describe('emitSubmit', () => {
      it('emits a submit event', () => {
        vm.emitSubmit(dummyEvent);

        expect(vm.$emit).toHaveBeenCalledWith('submit', dummyEvent);
      });
    });
  });

  describe('slots', () => {
    const slotContent = 'this should go into the slot';
    const modalWithSlot = (slotName) => {
      let template;
      if (slotName) {
        template = `
          <gl-modal>
            <template slot="${slotName}">${slotContent}</template>
          </gl-modal>
        `;
      } else {
        template = `<gl-modal>${slotContent}</gl-modal>`;
      }

      return Vue.extend({
        components: {
          GlModal,
        },
        template,
      });
    };

    describe('default slot', () => {
      beforeEach(() => {
        vm = mountComponent(modalWithSlot());
      });

      it('sets the modal body', () => {
        const modalBody = vm.$el.querySelector('.modal-body');
        expect(modalBody.innerHTML).toBe(slotContent);
      });
    });

    describe('header slot', () => {
      beforeEach(() => {
        vm = mountComponent(modalWithSlot('header'));
      });

      it('sets the modal header', () => {
        const modalHeader = vm.$el.querySelector('.modal-header');
        expect(modalHeader.innerHTML).toBe(slotContent);
      });
    });

    describe('title slot', () => {
      beforeEach(() => {
        vm = mountComponent(modalWithSlot('title'));
      });

      it('sets the modal title', () => {
        const modalTitle = vm.$el.querySelector('.modal-title');
        expect(modalTitle.innerHTML).toBe(slotContent);
      });
    });

    describe('footer slot', () => {
      beforeEach(() => {
        vm = mountComponent(modalWithSlot('footer'));
      });

      it('sets the modal footer', () => {
        const modalFooter = vm.$el.querySelector('.modal-footer');
        expect(modalFooter.innerHTML).toBe(slotContent);
      });
    });
  });
});
