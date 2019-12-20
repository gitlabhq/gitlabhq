import Vue from 'vue';
import createComponent from 'spec/helpers/vue_mount_component_helper';
import upload from '~/ide/components/new_dropdown/upload.vue';

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
      spyOn(FileReader.prototype, 'readAsDataURL');
    });

    it('calls readAsDataURL for all files', () => {
      const file = {
        type: 'images/png',
      };

      vm.readFile(file);

      expect(FileReader.prototype.readAsDataURL).toHaveBeenCalledWith(file);
    });
  });

  describe('createFile', () => {
    const textTarget = {
      result: 'base64,cGxhaW4gdGV4dA==',
    };
    const binaryTarget = {
      result: 'base64,w4I=',
    };
    const textFile = {
      name: 'textFile',
      type: 'text/plain',
    };
    const binaryFile = {
      name: 'binaryFile',
      type: 'image/png',
    };

    it('creates file in plain text (without encoding) if the file content is plain text', () => {
      vm.createFile(textTarget, textFile);

      expect(vm.$emit).toHaveBeenCalledWith('create', {
        name: textFile.name,
        type: 'blob',
        content: 'plain text',
        base64: false,
        binary: false,
        rawPath: '',
      });
    });

    it('splits content on base64 if binary', () => {
      vm.createFile(binaryTarget, binaryFile);

      expect(vm.$emit).toHaveBeenCalledWith('create', {
        name: binaryFile.name,
        type: 'blob',
        content: binaryTarget.result.split('base64,')[1],
        base64: true,
        binary: true,
        rawPath: binaryTarget.result,
      });
    });
  });
});
