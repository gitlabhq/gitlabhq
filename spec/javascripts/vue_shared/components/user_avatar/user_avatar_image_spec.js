import Vue from 'vue';
import { placeholderImage } from '~/lazy_loader';
import userAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

const DEFAULT_PROPS = {
  size: 99,
  imgSrc: 'myavatarurl.com',
  imgAlt: 'mydisplayname',
  cssClasses: 'myextraavatarclass',
  tooltipText: 'tooltip text',
  tooltipPlacement: 'bottom',
};

describe('User Avatar Image Component', function () {
  let vm;
  let UserAvatarImage;

  beforeEach(() => {
    UserAvatarImage = Vue.extend(userAvatarImage);
  });

  describe('Initialization', function () {
    beforeEach(function () {
      vm = mountComponent(UserAvatarImage, {
        ...DEFAULT_PROPS,
      }).$mount();
    });

    it('should return a defined Vue component', function () {
      expect(vm).toBeDefined();
    });

    it('should have <img> as a child element', function () {
      expect(vm.$el.tagName).toBe('IMG');
      expect(vm.$el.getAttribute('src')).toBe(DEFAULT_PROPS.imgSrc);
      expect(vm.$el.getAttribute('data-src')).toBe(DEFAULT_PROPS.imgSrc);
      expect(vm.$el.getAttribute('alt')).toBe(DEFAULT_PROPS.imgAlt);
    });

    it('should properly compute tooltipContainer', function () {
      expect(vm.tooltipContainer).toBe('body');
    });

    it('should properly render tooltipContainer', function () {
      expect(vm.$el.getAttribute('data-container')).toBe('body');
    });

    it('should properly compute avatarSizeClass', function () {
      expect(vm.avatarSizeClass).toBe('s99');
    });

    it('should properly render img css', function () {
      const classList = vm.$el.classList;
      const containsAvatar = classList.contains('avatar');
      const containsSizeClass = classList.contains('s99');
      const containsCustomClass = classList.contains(DEFAULT_PROPS.cssClasses);
      const lazyClass = classList.contains('lazy');

      expect(containsAvatar).toBe(true);
      expect(containsSizeClass).toBe(true);
      expect(containsCustomClass).toBe(true);
      expect(lazyClass).toBe(false);
    });
  });

  describe('Initialization when lazy', function () {
    beforeEach(function () {
      vm = mountComponent(UserAvatarImage, {
        ...DEFAULT_PROPS,
        lazy: true,
      }).$mount();
    });

    it('should add lazy attributes', function () {
      const classList = vm.$el.classList;
      const lazyClass = classList.contains('lazy');

      expect(lazyClass).toBe(true);
      expect(vm.$el.getAttribute('src')).toBe(placeholderImage);
      expect(vm.$el.getAttribute('data-src')).toBe(DEFAULT_PROPS.imgSrc);
    });
  });
});
