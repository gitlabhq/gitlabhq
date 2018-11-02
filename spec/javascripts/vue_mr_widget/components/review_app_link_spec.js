import Vue from 'vue';
import component from '~/vue_merge_request_widget/components/review_app_link.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('review app link', () => {
  const Component = Vue.extend(component);
  const props = {
    link: '/review',
    cssClass: 'js-link',
  };
  let vm;
  let el;

  beforeEach(() => {
    vm = mountComponent(Component, props);
    el = vm.$el;
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders provided link as href attribute', () => {
    expect(el.getAttribute('href')).toEqual(props.link);
  });

  it('renders provided cssClass as class attribute', () => {
    expect(el.getAttribute('class')).toEqual(props.cssClass);
  });

  it('renders View app text', () => {
    expect(el.textContent.trim()).toEqual('View app');
  });

  it('renders svg icon', () => {
    expect(el.querySelector('svg')).not.toBeNull();
  });
});
