import Vue from 'vue';
import imageFrame from '~/image_diff/components/image_frame.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';
import * as mockData from '../mock_data';

describe('imageFrame component', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(imageFrame);
    vm = mountComponent(Component, mockData.imageFrameData);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render frame', () => {
    expect(vm.$el.classList.contains('frame')).toEqual(true);
  });

  it('should render frame class', () => {
    expect(vm.$el.classList.contains(mockData.imageFrameData.className)).toEqual(true);
  });

  it('should render image', () => {
    expect(vm.$el.querySelector('img')).toBeDefined();
  });

  it('should render image source', () => {
    expect(vm.$el.querySelector('img').getAttribute('src')).toEqual(mockData.imageFrameData.src);
  });

  it('should render image alt', () => {
    expect(vm.$el.querySelector('img').getAttribute('alt')).toEqual(mockData.imageFrameData.alt);
  });
});
