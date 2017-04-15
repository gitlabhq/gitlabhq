import Vue from 'vue';
import UserAvatarSizeMixin from '~/vue_shared/components/user_avatar/user_avatar_size_mixin';

describe('User Avatar Size Mixin', () => {
  beforeEach(() => {
    this.vueInstance = new Vue({
      data: {
        size: 99,
      },
      mixins: [UserAvatarSizeMixin],
    });
  });

  describe('#avatarSizeClass', () => {
    it('should be a defined computed value', () => {
      expect(this.vueInstance.avatarSizeClass).toBeDefined();
    });

    it('should correctly transform size into the class name', () => {
      expect(this.vueInstance.avatarSizeClass).toBe('s99');
    });
  });

  describe('#avatarSizeStylesMap', () => {
    it('should be a defined computed value', () => {
      expect(this.vueInstance.avatarSizeStylesMap).toBeDefined();
    });

    it('should return a correctly formatted styles width', () => {
      expect(this.vueInstance.avatarSizeStylesMap.width).toBe('99px');
    });

    it('should return a correctly formatted styles height', () => {
      expect(this.vueInstance.avatarSizeStylesMap.height).toBe('99px');
    });
  });
});
