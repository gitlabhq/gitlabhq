import Vue from 'vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import store from '~/ide/stores';
import newDropdown from '~/ide/components/new_dropdown/index.vue';
import { resetStore } from '../../helpers';

describe('new dropdown component', () => {
  let vm;

  beforeEach(() => {
    const component = Vue.extend(newDropdown);

    vm = createComponentWithStore(component, store, {
      branch: 'master',
      path: '',
      mouseOver: false,
      type: 'tree',
    });

    vm.$store.state.currentProjectId = 'abcproject';
    vm.$store.state.path = '';
    vm.$store.state.trees['abcproject/mybranch'] = {
      tree: [],
    };

    spyOn(vm, 'openNewEntryModal');

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders new file, upload and new directory links', () => {
    const buttons = vm.$el.querySelectorAll('.dropdown-menu button');

    expect(buttons[0].textContent.trim()).toBe('New file');
    expect(buttons[1].textContent.trim()).toBe('Upload file');
    expect(buttons[2].textContent.trim()).toBe('New directory');
  });

  describe('createNewItem', () => {
    it('sets modalType to blob when new file is clicked', () => {
      vm.$el.querySelectorAll('.dropdown-menu button')[0].click();

      expect(vm.openNewEntryModal).toHaveBeenCalledWith({ type: 'blob', path: '' });
    });

    it('sets modalType to tree when new directory is clicked', () => {
      vm.$el.querySelectorAll('.dropdown-menu button')[2].click();

      expect(vm.openNewEntryModal).toHaveBeenCalledWith({ type: 'tree', path: '' });
    });
  });

  describe('isOpen', () => {
    it('scrolls dropdown into view', done => {
      spyOn(vm.$refs.dropdownMenu, 'scrollIntoView');

      vm.isOpen = true;

      setTimeout(() => {
        expect(vm.$refs.dropdownMenu.scrollIntoView).toHaveBeenCalledWith({
          block: 'nearest',
        });

        done();
      });
    });
  });

  describe('delete entry', () => {
    it('calls delete action', () => {
      spyOn(vm, 'deleteEntry');

      vm.$el.querySelectorAll('.dropdown-menu button')[4].click();

      expect(vm.deleteEntry).toHaveBeenCalledWith('');
    });
  });
});
