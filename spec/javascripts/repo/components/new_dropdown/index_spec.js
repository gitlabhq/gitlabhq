import Vue from 'vue';
import newDropdown from '~/repo/components/new_dropdown/index.vue';
import createComponent from '../../../helpers/vue_mount_component_helper';

describe('new dropdown component', () => {
  let vm;

  beforeEach(() => {
    const component = Vue.extend(newDropdown);

    vm = createComponent(component);
  });

  afterEach(() => {
    vm.$destroy();
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
