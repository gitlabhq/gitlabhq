import Vue from 'vue';
import avatarSvg from 'icons/_icon_random.svg';
import UserAvatarSvg from '~/vue_shared/components/user_avatar/user_avatar_svg.vue';

const UserAvatarSvgComponent = Vue.extend(UserAvatarSvg);

describe('User Avatar Svg Component', function() {
  describe('Initialization', function() {
    beforeEach(function() {
      this.propsData = {
        size: 99,
        svg: avatarSvg,
      };

      this.userAvatarSvg = new UserAvatarSvgComponent({
        propsData: this.propsData,
      }).$mount();
    });

    it('should return a defined Vue component', function() {
      expect(this.userAvatarSvg).toBeDefined();
    });

    it('should have <svg> as a child element', function() {
      expect(this.userAvatarSvg.$el.tagName).toEqual('svg');
      expect(this.userAvatarSvg.$el.innerHTML).toContain('<path');
    });
  });
});
