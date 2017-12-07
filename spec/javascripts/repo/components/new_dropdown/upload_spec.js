import Vue from 'vue';
import upload from '~/ide/components/new_dropdown/upload.vue';
import store from '~/ide/stores';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';
import { resetStore } from '../../helpers';

describe('new dropdown upload', () => {
  let vm;
  let projectTree;

  beforeEach(() => {
    const Component = Vue.extend(upload);

    store.state.projects.abcproject = {
      web_url: '',
    };
    store.state.trees = [];
    store.state.trees['abcproject/mybranch'] = {
      tree: [],
    };
    projectTree = store.state.trees['abcproject/mybranch'];

    vm = createComponentWithStore(Component, store, {
      projectId: 'abcproject',
      branchId: 'master',
      path: '',
      parent: projectTree,
    });

    vm.entryName = 'testing';

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
        const baseTree = vm.$store.state.trees['abcproject/mybranch'].tree;
        expect(baseTree.length).toBe(1);
        expect(baseTree[0].name).toBe(file.name);
        expect(baseTree[0].content).toBe(target.result);

        done();
      });
    });

    it('creates new file in path', (done) => {
      vm.$store.state.path = 'testing';
      vm.createFile(target, file, true);

      vm.$nextTick(() => {
        const baseTree = vm.$store.state.trees['abcproject/mybranch'].tree;
        expect(baseTree.length).toBe(1);
        expect(baseTree[0].name).toBe(file.name);
        expect(baseTree[0].content).toBe(target.result);
        expect(baseTree[0].path).toBe(`testing/${file.name}`);

        done();
      });
    });

    it('splits content on base64 if binary', (done) => {
      vm.createFile(binaryTarget, file, false);

      vm.$nextTick(() => {
        const baseTree = vm.$store.state.trees['abcproject/mybranch'].tree;
        expect(baseTree.length).toBe(1);
        expect(baseTree[0].name).toBe(file.name);
        expect(baseTree[0].content).toBe(binaryTarget.result.split('base64,')[1]);
        expect(baseTree[0].base64).toBe(true);

        done();
      });
    });
  });
});
