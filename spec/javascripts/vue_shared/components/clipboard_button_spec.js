import Vue from 'vue';
import clipboardButton from '~/vue_shared/components/clipboard_button.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('clipboard button', () => {
  const Component = Vue.extend(clipboardButton);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('without gfm', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        text: 'copy me',
        title: 'Copy this value into Clipboard!',
        cssClass: 'btn-danger',
      });
    });

    it('renders a button for clipboard', () => {
      expect(vm.$el.tagName).toEqual('BUTTON');
      expect(vm.$el.getAttribute('data-clipboard-text')).toEqual('copy me');
      expect(vm.$el).toHaveSpriteIcon('duplicate');
    });

    it('should have a tooltip with default values', () => {
      expect(vm.$el.getAttribute('data-original-title')).toEqual('Copy this value into Clipboard!');
      expect(vm.$el.getAttribute('data-placement')).toEqual('top');
      expect(vm.$el.getAttribute('data-container')).toEqual(null);
    });

    it('should render provided classname', () => {
      expect(vm.$el.classList).toContain('btn-danger');
    });
  });

  describe('with gfm', () => {
    it('sets data-clipboard-text with gfm', () => {
      vm = mountComponent(Component, {
        text: 'copy me',
        gfm: '`path/to/file`',
        title: 'Copy this value into Clipboard!',
        cssClass: 'btn-danger',
      });
      expect(vm.$el.getAttribute('data-clipboard-text')).toEqual(
        '{"text":"copy me","gfm":"`path/to/file`"}',
      );
    });
  });
});
