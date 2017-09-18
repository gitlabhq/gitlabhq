import Vue from 'vue';
import twoUpView from '~/image_diff/components/two_up_view.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';
import * as mockData from '../mock_data';

describe('twoUpView component', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(twoUpView);
    vm = mountComponent(Component, mockData.imageReplacedData);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('sets image type meta mockData.imageReplacedData', () => {
    vm.loadMeta('added', mockData.loadEvent);

    expect(vm.added.width).toEqual(mockData.loadEvent.target.naturalWidth);
    expect(vm.added.height).toEqual(mockData.loadEvent.target.naturalHeight);
  });

  describe('deleted image', () => {
    it('should render deleted image frame', () => {
      expect(vm.$el.querySelector('.frame.deleted img')).toBeDefined();
    });

    it('should render deleted image size', () => {
      const fileSize = vm.$el.querySelector('.frame.deleted + .image-info .meta-filesize').innerText.trim();
      expect(fileSize).toEqual(mockData.imageReplacedData.deleted.size);
    });

    it('should render deleted image width and height when image is loaded', (done) => {
      vm.loadMeta('deleted', mockData.loadEvent);

      Vue.nextTick(() => {
        const width = vm.$el.querySelector('.frame.deleted + .image-info .meta-width').innerText.trim();
        const height = vm.$el.querySelector('.frame.deleted + .image-info .meta-height').innerText.trim();
        expect(width).toEqual(`${mockData.loadEvent.target.naturalWidth}px`);
        expect(height).toEqual(`${mockData.loadEvent.target.naturalHeight}px`);
        done();
      });
    });
  });

  describe('added image', () => {
    it('should render added image frame', () => {
      expect(vm.$el.querySelector('.frame.added img')).toBeDefined();
    });

    it('should render added image size', () => {
      const fileSize = vm.$el.querySelector('.frame.added + .image-info .meta-filesize').innerText.trim();
      expect(fileSize).toEqual(mockData.imageReplacedData.added.size);
    });

    it('should render added image width and height when image is loaded', (done) => {
      vm.loadMeta('added', mockData.loadEvent);

      Vue.nextTick(() => {
        const width = vm.$el.querySelector('.frame.added + .image-info .meta-width').innerText.trim();
        const height = vm.$el.querySelector('.frame.added + .image-info .meta-height').innerText.trim();
        expect(width).toEqual(`${mockData.loadEvent.target.naturalWidth}px`);
        expect(height).toEqual(`${mockData.loadEvent.target.naturalHeight}px`);
        done();
      });
    });
  });
});
