import Vue from 'vue';
import upload from '~/ide/components/new_dropdown/upload.vue';
import createComponent from 'spec/helpers/vue_mount_component_helper';

describe('new dropdown upload', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(upload);

    vm = createComponent(Component, {
      path: '',
    });

    vm.entryName = 'testing';

    spyOn(vm, '$emit');
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('openFile', () => {
    it('calls for each file', () => {
      const files = ['test', 'test2', 'test3'];

      spyOn(vm, 'readFile');
      spyOnProperty(vm.$refs.fileUpload, 'files').and.returnValue(files);

      vm.openFile();

      expect(vm.readFile.calls.count()).toBe(3);

      files.forEach((file, i) => {
        expect(vm.readFile.calls.argsFor(i)).toEqual([file]);
      });
    });
  });

  describe('readFile', () => {
    beforeEach(() => {
      spyOn(FileReader.prototype, 'readAsBinaryString');
    });

    it('calls readAsBinaryString for all files', () => {
      const file = {
        type: 'text/html',
      };

      vm.readFile(file);

      expect(FileReader.prototype.readAsBinaryString).toHaveBeenCalledWith(file);
    });
  });

  describe('createFile', () => {
    const target = {
      result: 'content',
    };
    const file = {
      name: 'file',
    };

    it('creates new file', () => {
      vm.createFile(target, file, true);

      expect(vm.$emit).toHaveBeenCalledWith('create', {
        name: file.name,
        type: 'blob',
        content: target.result,
      });
    });
  });
});
