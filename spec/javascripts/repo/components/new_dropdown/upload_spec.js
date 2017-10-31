import Vue from 'vue';
import upload from '~/repo/components/new_dropdown/upload.vue';
import eventHub from '~/repo/event_hub';
import createComponent from '../../../helpers/vue_mount_component_helper';

describe('new dropdown upload', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(upload);

    vm = createComponent(Component, {
      currentPath: '',
    });
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

    beforeEach(() => {
      spyOn(eventHub, '$emit');
    });

    it('emits createNewEntry event', () => {
      vm.createFile(target, file, true);

      expect(eventHub.$emit).toHaveBeenCalledWith('createNewEntry', {
        name: 'file',
        type: 'blob',
        content: 'content',
        toggleModal: false,
        base64: false,
      }, true);
    });

    it('createNewEntry event name contains current path', () => {
      vm.currentPath = 'testing';
      vm.createFile(target, file, true);

      expect(eventHub.$emit).toHaveBeenCalledWith('createNewEntry', {
        name: 'testing/file',
        type: 'blob',
        content: 'content',
        toggleModal: false,
        base64: false,
      }, true);
    });

    it('splits content on base64 if binary', () => {
      vm.createFile(binaryTarget, file, false);

      expect(eventHub.$emit).toHaveBeenCalledWith('createNewEntry', {
        name: 'file',
        type: 'blob',
        content: 'base64content',
        toggleModal: false,
        base64: true,
      }, false);
    });
  });
});
