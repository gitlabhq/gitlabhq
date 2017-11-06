import Vue from 'vue';
import store from '~/repo/stores';
import newDropdown from '~/repo/components/new_dropdown/index.vue';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';
import { resetStore } from '../../helpers';

describe('new dropdown component', () => {
  let vm;

  beforeEach(() => {
    const component = Vue.extend(newDropdown);

    vm = createComponentWithStore(component, store);

    vm.$store.state.path = '';

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders new file and new directory links', () => {
    expect(vm.$el.querySelectorAll('a')[0].textContent.trim()).toBe('New file');
    expect(vm.$el.querySelectorAll('a')[1].textContent.trim()).toBe('New directory');
  });

  describe('createNewItem', () => {
    it('sets modalType to blob when new file is clicked', () => {
      vm.$el.querySelectorAll('a')[0].click();

      expect(vm.modalType).toBe('blob');
    });

    it('sets modalType to tree when new directory is clicked', () => {
      vm.$el.querySelectorAll('a')[1].click();

      expect(vm.modalType).toBe('tree');
    });

    it('opens modal when link is clicked', (done) => {
      vm.$el.querySelectorAll('a')[0].click();

      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.modal')).not.toBeNull();

        done();
      });
    });
  });

  describe('toggleModalOpen', () => {
    it('closes modal after toggling', (done) => {
      vm.toggleModalOpen();

      Vue.nextTick()
        .then(() => {
          expect(vm.$el.querySelector('.modal')).not.toBeNull();
        })
        .then(vm.toggleModalOpen)
        .then(() => {
          expect(vm.$el.querySelector('.modal')).toBeNull();
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
