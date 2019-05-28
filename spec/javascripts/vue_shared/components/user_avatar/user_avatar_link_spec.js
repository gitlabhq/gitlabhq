import _ from 'underscore';
import Vue from 'vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import { TEST_HOST } from 'spec/test_constants';

describe('User Avatar Link Component', function() {
  beforeEach(function() {
    this.propsData = {
      linkHref: `${TEST_HOST}/myavatarurl.com`,
      imgSize: 99,
      imgSrc: `${TEST_HOST}/myavatarurl.com`,
      imgAlt: 'mydisplayname',
      imgCssClasses: 'myextraavatarclass',
      tooltipText: 'tooltip text',
      tooltipPlacement: 'bottom',
      username: 'username',
    };

    const UserAvatarLinkComponent = Vue.extend(UserAvatarLink);

    this.userAvatarLink = new UserAvatarLinkComponent({
      propsData: this.propsData,
    }).$mount();

    [this.userAvatarImage] = this.userAvatarLink.$children;
  });

  it('should return a defined Vue component', function() {
    expect(this.userAvatarLink).toBeDefined();
  });

  it('should have user-avatar-image registered as child component', function() {
    expect(this.userAvatarLink.$options.components.userAvatarImage).toBeDefined();
  });

  it('user-avatar-link should have user-avatar-image as child component', function() {
    expect(this.userAvatarImage).toBeDefined();
  });

  it('should render <a> as a child element', function() {
    const link = this.userAvatarLink.$el;

    expect(link.tagName).toBe('A');
    expect(link.href).toBe(this.propsData.linkHref);
  });

  it('renders imgSrc with imgSize as image', function() {
    const { imgSrc, imgSize } = this.propsData;
    const image = this.userAvatarLink.$el.querySelector('img');

    expect(image).not.toBeNull();
    expect(image.src).toBe(`${imgSrc}?width=${imgSize}`);
  });

  it('should return necessary props as defined', function() {
    _.each(this.propsData, (val, key) => {
      expect(this.userAvatarLink[key]).toBeDefined();
    });
  });

  describe('no username', function() {
    beforeEach(function(done) {
      this.userAvatarLink.username = '';

      Vue.nextTick(done);
    });

    it('should only render image tag in link', function() {
      const childElements = this.userAvatarLink.$el.childNodes;

      expect(this.userAvatarLink.$el.querySelector('img')).not.toBe('null');

      // Vue will render the hidden component as <!---->
      expect(childElements[1].tagName).toBeUndefined();
    });

    it('should render avatar image tooltip', function() {
      expect(this.userAvatarLink.shouldShowUsername).toBe(false);
      expect(this.userAvatarLink.avatarTooltipText).toEqual(this.propsData.tooltipText);
    });
  });

  describe('username', function() {
    it('should not render avatar image tooltip', function() {
      expect(this.userAvatarLink.$el.querySelector('.js-user-avatar-image-toolip')).toBeNull();
    });

    it('should render username prop in <span>', function() {
      expect(
        this.userAvatarLink.$el.querySelector('.js-user-avatar-link-username').innerText.trim(),
      ).toEqual(this.propsData.username);
    });

    it('should render text tooltip for <span>', function() {
      expect(
        this.userAvatarLink.$el.querySelector('.js-user-avatar-link-username').dataset
          .originalTitle,
      ).toEqual(this.propsData.tooltipText);
    });

    it('should render text tooltip placement for <span>', function() {
      expect(
        this.userAvatarLink.$el
          .querySelector('.js-user-avatar-link-username')
          .getAttribute('tooltip-placement'),
      ).toEqual(this.propsData.tooltipPlacement);
    });
  });
});
