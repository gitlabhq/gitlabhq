import Vue from 'vue';
import swipeView from '~/image_diff/components/swipe_view.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';
import * as mockData from '../mock_data';

describe('swipeView component', () => {
  let vm;
  window.gl = window.gl || {};
  const existingImageFile = window.gl.ImageFile;

  beforeEach(() => {
    window.gl.ImageFile = mockData.ImageFile;

    spyOn(window.gl.ImageFile.prototype.views.swipe, 'call').and.callFake(() => {});

    const Component = Vue.extend(swipeView);
    vm = mountComponent(Component, mockData.imageReplacedData);
  });

  afterEach(() => {
    vm.$destroy();
    window.gl.ImageFile = existingImageFile;
  });

  it('should render deleted image frame', () => {
    expect(vm.$el.querySelector('.frame.deleted img')).toBeDefined();
  });

  it('should render added image frame', () => {
    expect(vm.$el.querySelector('.frame.added img')).toBeDefined();
  });

  it('should call gl.ImageFile', () => {
    expect(window.gl.ImageFile.prototype.views.swipe.call).toHaveBeenCalled();
  });
});
