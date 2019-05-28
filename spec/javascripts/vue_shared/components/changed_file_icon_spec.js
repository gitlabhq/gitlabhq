import Vue from 'vue';
import changedFileIcon from '~/vue_shared/components/changed_file_icon.vue';
import createComponent from 'spec/helpers/vue_mount_component_helper';

describe('Changed file icon', () => {
  let vm;

  function factory(props = {}) {
    const component = Vue.extend(changedFileIcon);

    vm = createComponent(component, {
      ...props,
      file: {
        tempFile: false,
        changed: true,
      },
    });
  }

  afterEach(() => {
    vm.$destroy();
  });

  it('centers icon', () => {
    factory({
      isCentered: true,
    });

    expect(vm.$el.classList).toContain('ml-auto');
  });

  describe('changedIcon', () => {
    it('equals file-modified when not a temp file and has changes', () => {
      factory();

      expect(vm.changedIcon).toBe('file-modified');
    });

    it('equals file-addition when a temp file', () => {
      factory();

      vm.file.tempFile = true;

      expect(vm.changedIcon).toBe('file-addition');
    });
  });

  describe('changedIconClass', () => {
    it('includes file-modified when not a temp file', () => {
      factory();

      expect(vm.changedIconClass).toContain('file-modified');
    });

    it('includes file-addition when a temp file', () => {
      factory();

      vm.file.tempFile = true;

      expect(vm.changedIconClass).toContain('file-addition');
    });
  });
});
