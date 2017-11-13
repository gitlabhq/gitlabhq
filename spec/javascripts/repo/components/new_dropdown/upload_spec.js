import Vue from 'vue';
import upload from '~/repo/components/new_dropdown/upload.vue';
import store from '~/repo/stores';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';
import { resetStore } from '../../helpers';

describe('new dropdown upload', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(upload);

    vm = createComponentWithStore(Component, store, {
      path: '',
    });

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  describe('readFile', () => {
    beforeEach(() => {
      spyOn(FileReader.prototype, 'readAsText');
      spyOn(FileReader.prototype, 'readAsDataURL');
    });

    it('calls readAsText for text files', () => {
      const file = {
        type: 'text/html',
      };

      vm.readFile(file);

      expect(FileReader.prototype.readAsText).toHaveBeenCalledWith(file);
    });

    it('calls readAsDataURL for non-text files', () => {
      const file = {
        type: 'images/png',
      };

      vm.readFile(file);

      expect(FileReader.prototype.readAsDataURL).toHaveBeenCalledWith(file);
    });
  });

  describe('createFile', () => {
    const target = {
      result: 'content',
    };
    const binaryTarget = {
      result: 'base64,base64content',
    };
    const file = {
      name: 'file',
    };

    it('creates new file', (done) => {
      vm.createFile(target, file, true);

      vm.$nextTick(() => {
        expect(vm.$store.state.tree.length).toBe(1);
        expect(vm.$store.state.tree[0].name).toBe(file.name);
        expect(vm.$store.state.tree[0].content).toBe(target.result);

        done();
      });
    });

    it('creates new file in path', (done) => {
      vm.$store.state.path = 'testing';
      vm.createFile(target, file, true);

      vm.$nextTick(() => {
        expect(vm.$store.state.tree.length).toBe(1);
        expect(vm.$store.state.tree[0].name).toBe(file.name);
        expect(vm.$store.state.tree[0].content).toBe(target.result);
        expect(vm.$store.state.tree[0].path).toBe(`testing/${file.name}`);

        done();
      });
    });

    it('splits content on base64 if binary', (done) => {
      vm.createFile(binaryTarget, file, false);

      vm.$nextTick(() => {
        expect(vm.$store.state.tree.length).toBe(1);
        expect(vm.$store.state.tree[0].name).toBe(file.name);
        expect(vm.$store.state.tree[0].content).toBe(binaryTarget.result.split('base64,')[1]);
        expect(vm.$store.state.tree[0].base64).toBe(true);

        done();
      });
    });
  });
});
