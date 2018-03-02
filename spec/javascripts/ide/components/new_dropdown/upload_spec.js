import Vue from 'vue';
import upload from 'ee/ide/components/new_dropdown/upload.vue';
import store from 'ee/ide/stores';
import service from 'ee/ide/services';
import router from 'ee/ide/ide_router';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { resetStore } from '../../helpers';

describe('new dropdown upload', () => {
  let vm;
  let projectTree;

  beforeEach(() => {
    spyOn(service, 'getProjectData').and.returnValue(Promise.resolve({
      data: {
        id: '123',
      },
    }));

    spyOn(service, 'getBranchData').and.returnValue(Promise.resolve({
      data: {
        commit: {
          id: '123branch',
        },
      },
    }));

    spyOn(service, 'getTreeData').and.returnValue(Promise.resolve({
      headers: {
        'page-title': 'test',
      },
      json: () => Promise.resolve({
        last_commit_path: 'last_commit_path',
        parent_tree_url: 'parent_tree_url',
        path: '/',
        trees: [{ name: 'tree' }],
        blobs: [{ name: 'blob' }],
        submodules: [{ name: 'submodule' }],
      }),
    }));

    spyOn(router, 'push');

    const Component = Vue.extend(upload);

    store.state.projects.abcproject = {
      web_url: '',
    };
    store.state.currentProjectId = 'abcproject';
    store.state.trees = [];
    store.state.trees['abcproject/mybranch'] = {
      tree: [],
    };
    projectTree = store.state.trees['abcproject/mybranch'];

    vm = createComponentWithStore(Component, store, {
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
      const baseTree = vm.$store.state.trees['abcproject/mybranch'].tree;
      const tree = {
        type: 'tree',
        name: 'testing',
        path: 'testing',
        tree: [],
      };
      baseTree.push(tree);

      vm.parent = tree;
      vm.createFile(target, file, true);

      vm.$nextTick(() => {
        expect(baseTree.length).toBe(1);
        expect(baseTree[0].tree[0].name).toBe(file.name);
        expect(baseTree[0].tree[0].content).toBe(target.result);
        expect(baseTree[0].tree[0].path).toBe(`testing/${file.name}`);

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
