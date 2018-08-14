import Vue from 'vue';
import store from '~/badges/store';
import BadgeForm from '~/badges/components/badge_form.vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { createDummyBadge } from '../dummy_badge';

describe('BadgeForm component', () => {
  const Component = Vue.extend(BadgeForm);
  let vm;

  beforeEach(() => {
    setFixtures(`
      <div id="dummy-element"></div>
    `);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('methods', () => {
    beforeEach(() => {
      vm = mountComponentWithStore(Component, {
        el: '#dummy-element',
        store,
        props: {
          isEditing: false,
        },
      });
    });

    describe('onCancel', () => {
      it('calls stopEditing', () => {
        spyOn(vm, 'stopEditing');

        vm.onCancel();

        expect(vm.stopEditing).toHaveBeenCalled();
      });
    });

    describe('onSubmit', () => {
      describe('if isEditing is true', () => {
        beforeEach(() => {
          spyOn(vm, 'saveBadge').and.returnValue(Promise.resolve());
          store.replaceState({
            ...store.state,
            isSaving: false,
            badgeInEditForm: createDummyBadge(),
          });
          vm.isEditing = true;
        });

        it('returns immediately if imageUrl is empty', () => {
          store.state.badgeInEditForm.imageUrl = '';

          vm.onSubmit();

          expect(vm.saveBadge).not.toHaveBeenCalled();
        });

        it('returns immediately if linkUrl is empty', () => {
          store.state.badgeInEditForm.linkUrl = '';

          vm.onSubmit();

          expect(vm.saveBadge).not.toHaveBeenCalled();
        });

        it('returns immediately if isSaving is true', () => {
          store.state.isSaving = true;

          vm.onSubmit();

          expect(vm.saveBadge).not.toHaveBeenCalled();
        });

        it('calls saveBadge', () => {
          vm.onSubmit();

          expect(vm.saveBadge).toHaveBeenCalled();
        });
      });

      describe('if isEditing is false', () => {
        beforeEach(() => {
          spyOn(vm, 'addBadge').and.returnValue(Promise.resolve());
          store.replaceState({
            ...store.state,
            isSaving: false,
            badgeInAddForm: createDummyBadge(),
          });
          vm.isEditing = false;
        });

        it('returns immediately if imageUrl is empty', () => {
          store.state.badgeInAddForm.imageUrl = '';

          vm.onSubmit();

          expect(vm.addBadge).not.toHaveBeenCalled();
        });

        it('returns immediately if linkUrl is empty', () => {
          store.state.badgeInAddForm.linkUrl = '';

          vm.onSubmit();

          expect(vm.addBadge).not.toHaveBeenCalled();
        });

        it('returns immediately if isSaving is true', () => {
          store.state.isSaving = true;

          vm.onSubmit();

          expect(vm.addBadge).not.toHaveBeenCalled();
        });

        it('calls addBadge', () => {
          vm.onSubmit();

          expect(vm.addBadge).toHaveBeenCalled();
        });
      });
    });
  });

  describe('if isEditing is false', () => {
    beforeEach(() => {
      vm = mountComponentWithStore(Component, {
        el: '#dummy-element',
        store,
        props: {
          isEditing: false,
        },
      });
    });

    it('renders one button', () => {
      const buttons = vm.$el.querySelectorAll('.row-content-block button');
      expect(buttons.length).toBe(1);
      const buttonAddElement = buttons[0];
      expect(buttonAddElement).toBeVisible();
      expect(buttonAddElement).toHaveText('Add badge');
    });
  });

  describe('if isEditing is true', () => {
    beforeEach(() => {
      vm = mountComponentWithStore(Component, {
        el: '#dummy-element',
        store,
        props: {
          isEditing: true,
        },
      });
    });

    it('renders two buttons', () => {
      const buttons = vm.$el.querySelectorAll('.row-content-block button');
      expect(buttons.length).toBe(2);
      const buttonSaveElement = buttons[0];
      expect(buttonSaveElement).toBeVisible();
      expect(buttonSaveElement).toHaveText('Save changes');
      const buttonCancelElement = buttons[1];
      expect(buttonCancelElement).toBeVisible();
      expect(buttonCancelElement).toHaveText('Cancel');
    });
  });
});
