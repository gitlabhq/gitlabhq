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

      this.imageElement = this.userAvatarImage.$el.outerHTML;
    });

    it('should return a defined Vue component', function () {
      expect(this.userAvatarImage).toBeDefined();
    });

    it('should have <img> as a child element', function () {
      const componentImgTag = this.userAvatarImage.$el.outerHTML;
      expect(componentImgTag).toContain('<img');
    });

    it('should return neccessary props as defined', function () {
      _.each(this.propsData, (val, key) => {
        expect(this.userAvatarImage[key]).toBeDefined();
      });
    });

    it('should properly compute tooltipContainer', function () {
      expect(this.userAvatarImage.tooltipContainer).toBe('body');
    });

    it('should properly render tooltipContainer', function () {
      expect(this.imageElement).toContain('data-container="body"');
    });

    it('should properly compute avatarSizeClass', function () {
      expect(this.userAvatarImage.avatarSizeClass).toBe('s99');
    });

    it('should properly compute imgCssClasses', function () {
      expect(this.userAvatarImage.imgCssClasses).toBe('avatar s99 myextraavatarclass');
    });

    it('should properly render imgCssClasses', function () {
      expect(this.imageElement).toContain('avatar s99 myextraavatarclass');
    });
  });
});
