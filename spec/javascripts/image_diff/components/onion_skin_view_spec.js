import Vue from 'vue';
import onionSkinView from '~/image_diff/components/onion_skin_view.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';
import * as mockData from '../mock_data';

describe('onionSkinView component', () => {
  let vm;
  window.gl = window.gl || {};
  const existingImageFile = window.gl.ImageFile;

  beforeEach(() => {
    window.gl.ImageFile = mockData.ImageFile;

    spyOn(window.gl.ImageFile.prototype.views['onion-skin'], 'call').and.callFake(() => {});

    const Component = Vue.extend(onionSkinView);
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
    expect(window.gl.ImageFile.prototype.views['onion-skin'].call).toHaveBeenCalled();
  });
});
