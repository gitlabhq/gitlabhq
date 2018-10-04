import Vue from 'vue';
import imageDiffViewer from '~/vue_shared/components/diff_viewer/viewers/image_diff_viewer.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { GREEN_BOX_IMAGE_URL, RED_BOX_IMAGE_URL } from 'spec/test_constants';

describe('ImageDiffViewer', () => {
  let vm;

  function createComponent(props) {
    const ImageDiffViewer = Vue.extend(imageDiffViewer);
    vm = mountComponent(ImageDiffViewer, props);
  }

  const triggerEvent = (eventName, el = vm.$el, clientX = 0) => {
    const event = document.createEvent('MouseEvents');
    event.initMouseEvent(
      eventName,
      true,
      true,
      window,
      1,
      clientX,
      0,
      clientX,
      0,
      false,
      false,
      false,
      false,
      0,
      null,
    );

    el.dispatchEvent(event);
  };

  const dragSlider = (sliderElement, dragPixel = 20) => {
    triggerEvent('mousedown', sliderElement);
    triggerEvent('mousemove', document.body, dragPixel);
    triggerEvent('mouseup', document.body);
  };

  afterEach(() => {
    vm.$destroy();
  });

  it('renders image diff for replaced', done => {
    createComponent({
      diffMode: 'replaced',
      newPath: GREEN_BOX_IMAGE_URL,
      oldPath: RED_BOX_IMAGE_URL,
    });

    setTimeout(() => {
      expect(vm.$el.querySelector('.added .image_file img').getAttribute('src')).toBe(
        GREEN_BOX_IMAGE_URL,
      );
      expect(vm.$el.querySelector('.deleted .image_file img').getAttribute('src')).toBe(
        RED_BOX_IMAGE_URL,
      );

      expect(vm.$el.querySelector('.view-modes-menu li.active').textContent.trim()).toBe('2-up');
      expect(vm.$el.querySelector('.view-modes-menu li:nth-child(2)').textContent.trim()).toBe(
        'Swipe',
      );
      expect(vm.$el.querySelector('.view-modes-menu li:nth-child(3)').textContent.trim()).toBe(
        'Onion skin',
      );

      done();
    });
  });

  it('renders image diff for new', done => {
    createComponent({
      diffMode: 'new',
      newPath: GREEN_BOX_IMAGE_URL,
      oldPath: '',
    });

    setTimeout(() => {
      expect(vm.$el.querySelector('.added .image_file img').getAttribute('src')).toBe(
        GREEN_BOX_IMAGE_URL,
      );

      done();
    });
  });

  it('renders image diff for deleted', done => {
    createComponent({
      diffMode: 'deleted',
      newPath: '',
      oldPath: RED_BOX_IMAGE_URL,
    });

    setTimeout(() => {
      expect(vm.$el.querySelector('.deleted .image_file img').getAttribute('src')).toBe(
        RED_BOX_IMAGE_URL,
      );

      done();
    });
  });

  describe('swipeMode', () => {
    beforeEach(done => {
      createComponent({
        diffMode: 'replaced',
        newPath: GREEN_BOX_IMAGE_URL,
        oldPath: RED_BOX_IMAGE_URL,
      });

      setTimeout(() => {
        done();
      });
    });

    it('switches to Swipe Mode', done => {
      vm.$el.querySelector('.view-modes-menu li:nth-child(2)').click();

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.view-modes-menu li.active').textContent.trim()).toBe('Swipe');
        done();
      });
    });

    it('drag handler is working', done => {
      vm.$el.querySelector('.view-modes-menu li:nth-child(2)').click();

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.swipe-bar').style.left).toBe('1px');
        expect(vm.$el.querySelector('.top-handle')).not.toBeNull();

        dragSlider(vm.$el.querySelector('.swipe-bar'), 40);

        vm.$nextTick(() => {
          expect(vm.$el.querySelector('.swipe-bar').style.left).toBe('-20px');
          done();
        });
      });
    });
  });

  describe('onionSkin', () => {
    beforeEach(done => {
      createComponent({
        diffMode: 'replaced',
        newPath: GREEN_BOX_IMAGE_URL,
        oldPath: RED_BOX_IMAGE_URL,
      });

      setTimeout(() => {
        done();
      });
    });

    it('switches to Onion Skin Mode', done => {
      vm.$el.querySelector('.view-modes-menu li:nth-child(3)').click();

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.view-modes-menu li.active').textContent.trim()).toBe(
          'Onion skin',
        );
        done();
      });
    });

    it('has working drag handler', done => {
      vm.$el.querySelector('.view-modes-menu li:nth-child(3)').click();

      vm.$nextTick(() => {
        dragSlider(vm.$el.querySelector('.dragger'));

        vm.$nextTick(() => {
          expect(vm.$el.querySelector('.dragger').style.left).toBe('20px');
          expect(vm.$el.querySelector('.added.frame').style.opacity).toBe('0.2');
          done();
        });
      });
    });
  });
});
