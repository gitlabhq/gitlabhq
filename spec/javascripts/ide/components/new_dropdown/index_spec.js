import Vue from 'vue';
import store from '~/ide/stores';
import newDropdown from '~/ide/components/new_dropdown/index.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { resetStore } from '../../helpers';

describe('new dropdown component', () => {
  let vm;

  beforeEach(() => {
    const component = Vue.extend(newDropdown);

    vm = createComponentWithStore(component, store, {
      branch: 'master',
      path: '',
    });

    vm.$store.state.currentProjectId = 'abcproject';
    vm.$store.state.path = '';
    vm.$store.state.trees['abcproject/mybranch'] = {
      tree: [],
    };

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders new file, upload and new directory links', () => {
    expect(vm.$el.querySelectorAll('a')[0].textContent.trim()).toBe('New file');
    expect(vm.$el.querySelectorAll('a')[1].textContent.trim()).toBe(
      'Upload file',
    );
    expect(vm.$el.querySelectorAll('a')[2].textContent.trim()).toBe(
      'New directory',
    );
  });

  describe('createNewItem', () => {
    it('sets modalType to blob when new file is clicked', () => {
      vm.$el.querySelectorAll('a')[0].click();

      expect(vm.modalType).toBe('blob');
    });

    it('sets modalType to tree when new directory is clicked', () => {
      vm.$el.querySelectorAll('a')[2].click();

      expect(vm.modalType).toBe('tree');
    });

    it('opens modal when link is clicked', done => {
      vm.$el.querySelectorAll('a')[0].click();

      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.modal')).not.toBeNull();

        done();
      });
    });
  });

  describe('hideModal', () => {
    beforeAll(done => {
      vm.openModal = true;
      Vue.nextTick(done);
    });

    it('closes modal after toggling', done => {
      vm.hideModal();

      Vue.nextTick()
        .then(() => {
          expect(vm.$el.querySelector('.modal')).toBeNull();
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
