import Vue from 'vue';
import { placeholderImage } from '~/lazy_loader';
import userAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import mountComponent, { mountComponentWithSlots } from 'spec/helpers/vue_mount_component_helper';
import defaultAvatarUrl from '~/../images/no_avatar.png';

const DEFAULT_PROPS = {
  size: 99,
  imgSrc: 'myavatarurl.com',
  imgAlt: 'mydisplayname',
  cssClasses: 'myextraavatarclass',
  tooltipText: 'tooltip text',
  tooltipPlacement: 'bottom',
};

describe('User Avatar Image Component', function() {
  let vm;
  let UserAvatarImage;

  beforeEach(() => {
    UserAvatarImage = Vue.extend(userAvatarImage);
  });

  describe('Initialization', function() {
    beforeEach(function() {
      vm = mountComponent(UserAvatarImage, {
        ...DEFAULT_PROPS,
      }).$mount();
    });

    it('should return a defined Vue component', function() {
      expect(vm).toBeDefined();
    });

    it('should have <img> as a child element', function() {
      const imageElement = vm.$el.querySelector('img');

      expect(imageElement).not.toBe(null);
      expect(imageElement.getAttribute('src')).toBe(`${DEFAULT_PROPS.imgSrc}?width=99`);
      expect(imageElement.getAttribute('data-src')).toBe(`${DEFAULT_PROPS.imgSrc}?width=99`);
      expect(imageElement.getAttribute('alt')).toBe(DEFAULT_PROPS.imgAlt);
    });

    it('should properly compute avatarSizeClass', function() {
      expect(vm.avatarSizeClass).toBe('s99');
    });

    it('should properly render img css', function() {
      const { classList } = vm.$el.querySelector('img');
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

  describe('Initialization when lazy', function() {
    beforeEach(function() {
      vm = mountComponent(UserAvatarImage, {
        ...DEFAULT_PROPS,
        lazy: true,
      }).$mount();
    });

    it('should add lazy attributes', function() {
      const imageElement = vm.$el.querySelector('img');
      const lazyClass = imageElement.classList.contains('lazy');

      expect(lazyClass).toBe(true);
      expect(imageElement.getAttribute('src')).toBe(placeholderImage);
      expect(imageElement.getAttribute('data-src')).toBe(`${DEFAULT_PROPS.imgSrc}?width=99`);
    });
  });

  describe('Initialization without src', function() {
    beforeEach(function() {
      vm = mountComponent(UserAvatarImage);
    });

    it('should have default avatar image', function() {
      const imageElement = vm.$el.querySelector('img');

      expect(imageElement.getAttribute('src')).toBe(defaultAvatarUrl);
    });
  });

  describe('dynamic tooltip content', () => {
    const props = DEFAULT_PROPS;
    const slots = {
      default: ['Action!'],
    };

    beforeEach(() => {
      vm = mountComponentWithSlots(UserAvatarImage, { props, slots }).$mount();
    });

    it('renders the tooltip slot', () => {
      expect(vm.$el.querySelector('.js-user-avatar-image-toolip')).not.toBe(null);
    });

    it('renders the tooltip content', () => {
      expect(vm.$el.querySelector('.js-user-avatar-image-toolip').textContent).toContain(
        slots.default[0],
      );
    });

    it('does not render tooltip data attributes for on avatar image', () => {
      const avatarImg = vm.$el.querySelector('img');

      expect(avatarImg.dataset.originalTitle).not.toBeDefined();
      expect(avatarImg.dataset.placement).not.toBeDefined();
      expect(avatarImg.dataset.container).not.toBeDefined();
    });
  });
});
