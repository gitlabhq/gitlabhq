import Vue from 'vue';
import clipboardButton from '~/vue_shared/components/clipboard_button.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('clipboard button', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(clipboardButton);
    vm = mountComponent(Component, {
      text: 'copy me',
      title: 'Copy this value into Clipboard!',
      cssClass: 'btn-danger',
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders a button for clipboard', () => {
    expect(vm.$el.tagName).toEqual('BUTTON');
    expect(vm.$el.getAttribute('data-clipboard-text')).toEqual('copy me');
    expect(vm.$el.querySelector('i').className).toEqual('fa fa-clipboard');
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
