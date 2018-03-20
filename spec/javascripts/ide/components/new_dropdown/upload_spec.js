import Vue from 'vue';
import upload from 'ee/ide/components/new_dropdown/upload.vue';
import createComponent from 'spec/helpers/vue_mount_component_helper';

describe('new dropdown upload', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(upload);

    vm = createComponent(Component, {
      branchId: 'master',
      path: '',
    });

    vm.entryName = 'testing';

    spyOn(vm, '$emit');
  });

  afterEach(() => {
    vm.$destroy();
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

    it('creates new file', () => {
      vm.createFile(target, file, true);

      expect(vm.$emit).toHaveBeenCalledWith('create', {
        name: file.name,
        branchId: 'master',
        type: 'blob',
        content: target.result,
        base64: false,
      });
    });

    it('splits content on base64 if binary', () => {
      vm.createFile(binaryTarget, file, false);

      expect(vm.$emit).toHaveBeenCalledWith('create', {
        name: file.name,
        branchId: 'master',
        type: 'blob',
        content: binaryTarget.result.split('base64,')[1],
        base64: true,
      });
    });
  });
});
