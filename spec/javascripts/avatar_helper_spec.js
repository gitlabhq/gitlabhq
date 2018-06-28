import $ from 'jquery';
import { renderAvatar } from '~/helpers/avatar_helper';

describe('avatar_helper', () => {
  describe('renderAvatar', () => {
    it('renders an image with the avatarUrl', () => {
      const avatarUrl = 'https://gitlab.com/not-real-assets/test.png';
      const entity = {
        avatar_url: avatarUrl,
      };

      const result = $(renderAvatar(entity));

      expect(result).toEqual('img');
      expect(result).toHaveAttr('src', avatarUrl);
    });

    it('renders an identicon if no avatarUrl', () => {
      const entity = {
        id: 5,
        name: 'walrus',
      };

      const result = $(renderAvatar(entity, { sizeClass: 's16' }));

      expect(result).toHaveClass('identicon');
      expect(result).toHaveClass('s16');
      expect(result.text().trim()).toEqual('W');
    });
  });
});
