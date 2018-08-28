import Vue from 'vue';
import userAvatarEmpty from '~/vue_shared/components/user_avatar/user_avatar_empty.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

const DEFAULT_PROPS = {
  size: 99,
  cssClasses: 'myextraavatarclass',
  tooltipText: 'tooltip text',
  tooltipPlacement: 'bottom',
};

describe('User Avatar Image Component', function() {
  let vm;
  let UserAvatarEmpty;

  beforeEach(() => {
    UserAvatarEmpty = Vue.extend(userAvatarEmpty);
  });

  describe('Initialization', function() {
    beforeEach(function() {
      vm = mountComponent(UserAvatarEmpty, {
        ...DEFAULT_PROPS,
      }).$mount();
    });

    it('should return a defined Vue component', function() {
      expect(vm).toBeDefined();
    });

    it('should have <span> as a child element', function() {
      expect(vm.$el.tagName).toBe('SPAN');
    });

    it('should properly compute tooltipContainer', function() {
      expect(vm.tooltipContainer).toBe('body');
    });

    it('should properly render tooltipContainer', function() {
      expect(vm.$el.getAttribute('data-container')).toBe('body');
    });

    it('should properly compute avatarSizeClass', function() {
      expect(vm.avatarSizeClass).toBe('s99');
    });

    it('should properly render css', function() {
      const { classList } = vm.$el;
      const containsAvatar = classList.contains('avatar');
      const containsSizeClass = classList.contains('s99');
      const containsCustomClass = classList.contains(DEFAULT_PROPS.cssClasses);
      const containsNoAvatar = classList.contains('no-avatar');

      expect(containsAvatar).toBe(true);
      expect(containsSizeClass).toBe(true);
      expect(containsCustomClass).toBe(true);
      expect(containsNoAvatar).toBe(true);
    });
  });
});
