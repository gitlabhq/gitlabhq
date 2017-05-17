import Vue from 'vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';

const UserAvatarImageComponent = Vue.extend(UserAvatarImage);

describe('User Avatar Image Component', function () {
  describe('Initialization', function () {
    beforeEach(function () {
      this.propsData = {
        size: 99,
        imgSrc: 'myavatarurl.com',
        imgAlt: 'mydisplayname',
        cssClasses: 'myextraavatarclass',
        tooltipText: 'tooltip text',
        tooltipPlacement: 'bottom',
      };

      this.userAvatarImage = new UserAvatarImageComponent({
        propsData: this.propsData,
      }).$mount();
    });

    it('should return a defined Vue component', function () {
      expect(this.userAvatarImage).toBeDefined();
    });

    it('should have <img> as a child element', function () {
      expect(this.userAvatarImage.$el.tagName).toBe('IMG');
    });

    it('should properly compute tooltipContainer', function () {
      expect(this.userAvatarImage.tooltipContainer).toBe('body');
    });

    it('should properly render tooltipContainer', function () {
      expect(this.userAvatarImage.$el.getAttribute('data-container')).toBe('body');
    });

    it('should properly compute avatarSizeClass', function () {
      expect(this.userAvatarImage.avatarSizeClass).toBe('s99');
    });

    it('should properly render img css', function () {
      const classList = this.userAvatarImage.$el.classList;
      const containsAvatar = classList.contains('avatar');
      const containsSizeClass = classList.contains('s99');
      const containsCustomClass = classList.contains('myextraavatarclass');

      expect(containsAvatar).toBe(true);
      expect(containsSizeClass).toBe(true);
      expect(containsCustomClass).toBe(true);
    });
  });
});
