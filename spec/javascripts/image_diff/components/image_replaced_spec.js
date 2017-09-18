import Vue from 'vue';
import imageReplaced from '~/image_diff/components/image_replaced.vue';
import viewTypes from '~/image_diff/constants';
import mountComponent from '../../helpers/vue_mount_component_helper';
import * as mockData from '../mock_data';

describe('imageReplaced component', () => {
  let vm;
  window.gl = window.gl || {};
  const existingImageFile = window.gl.ImageFile;

  beforeEach(() => {
    window.gl.ImageFile = mockData.ImageFile;

    const data = {
      images: mockData.imageReplacedData,
    };

    const Component = Vue.extend(imageReplaced);
    vm = mountComponent(Component, data);
  });

  afterEach(() => {
    vm.$destroy();
    window.gl.ImageFile = existingImageFile;
  });

  it('should render two-up-view by default', () => {
    expect(vm.$el.querySelector('.two-up.view')).toBeDefined();
  });

  it('should only render swipe-view if currentView is swipe', () => {
    vm.currentView = viewTypes.SWIPE;
    expect(vm.$el.querySelector('.swipe.view')).toBeDefined();
  });

  it('should only render onion-skin-view if currentView is onion-skin', () => {
    vm.currentView = viewTypes.ONION_SKIN;
    expect(vm.$el.querySelector('.onion-skin.view')).toBeDefined();
  });

  it('should change currentView when btn-group is toggled', () => {
    vm.$el.querySelector('.btn-group .btn:last-child').click();
    expect(vm.currentView).toEqual(viewTypes.ONION_SKIN);

    vm.$el.querySelector('.btn-group .btn:first-child').click();
    expect(vm.currentView).toEqual(viewTypes.TWO_UP);
  });
});
