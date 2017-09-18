import Vue from 'vue';
import imageDiffApp from '~/image_diff/components/image_diff_app.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';
import * as mockData from '../mock_data';

describe('imageDiffApp component', () => {
  let vm;
  let Component;

  beforeEach(() => {
    Component = Vue.extend(imageDiffApp);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('single image', () => {
    describe('added', () => {
      const { added } = mockData.imageReplacedData;

      beforeEach(() => {
        vm = mountComponent(Component, {
          images: {
            added,
          },
        });
      });

      it('should render added image frame', () => {
        expect(vm.$el.querySelector('.image .wrap .frame.added')).toBeDefined();
      });

      it('should render image size', () => {
        expect(vm.$el.querySelector('.image .wrap .image-info').innerText.trim()).toEqual(added.size);
      });
    });

    describe('deleted', () => {
      const { deleted } = mockData.imageReplacedData;

      beforeEach(() => {
        vm = mountComponent(Component, {
          images: {
            deleted,
          },
        });
      });

      it('should render deleted image frame', () => {
        expect(vm.$el.querySelector('.image .wrap .frame.deleted')).toBeDefined();
      });
    });
  });

  describe('multiple images', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        images: mockData.imageReplacedData,
      });
    });

    it('should not render image replaced if there is only one image', () => {
      expect(vm.$el.querySelector('.image .wrap .image-info')).toBeNull();
      expect(vm.$el.querySelector('.two-up.view')).toBeDefined();
    });
  });
});
