import _ from 'underscore';
import Vue from 'vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';

describe('User Avatar Link Component', function () {
  beforeEach(function () {
    this.propsData = {
      linkHref: 'myavatarurl.com',
      imgSize: 99,
      imgSrc: 'myavatarurl.com',
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

    this.userAvatarImage = this.userAvatarLink.$children[0];
  });

  it('should return a defined Vue component', function () {
    expect(this.userAvatarLink).toBeDefined();
  });

  it('should have user-avatar-image registered as child component', function () {
    expect(this.userAvatarLink.$options.components.userAvatarImage).toBeDefined();
  });

  it('user-avatar-link should have user-avatar-image as child component', function () {
    expect(this.userAvatarImage).toBeDefined();
  });

  it('should render <a> as a child element', function () {
    expect(this.userAvatarLink.$el.tagName).toBe('A');
  });

  it('should have <img> as a child element', function () {
    expect(this.userAvatarLink.$el.querySelector('img')).not.toBeNull();
  });

  it('should return neccessary props as defined', function () {
    _.each(this.propsData, (val, key) => {
      expect(this.userAvatarLink[key]).toBeDefined();
    });
  });

  describe('no username', function () {
    beforeEach(function (done) {
      this.userAvatarLink.username = '';

      Vue.nextTick(done);
    });

    it('should only render image tag in link', function () {
      const childElements = this.userAvatarLink.$el.childNodes;
      expect(childElements[0].tagName).toBe('IMG');

      // Vue will render the hidden component as <!---->
      expect(childElements[1].tagName).toBeUndefined();
    });

    it('should render avatar image tooltip', function () {
      expect(this.userAvatarLink.$el.querySelector('img').dataset.originalTitle).toEqual(this.propsData.tooltipText);
    });
  });

  describe('username', function () {
    it('should not render avatar image tooltip', function () {
      expect(this.userAvatarLink.$el.querySelector('img').dataset.originalTitle).toEqual('');
    });

    it('should render username prop in <span>', function () {
      expect(this.userAvatarLink.$el.querySelector('span').innerText.trim()).toEqual(this.propsData.username);
    });

    it('should render text tooltip for <span>', function () {
      expect(this.userAvatarLink.$el.querySelector('span').dataset.originalTitle).toEqual(this.propsData.tooltipText);
    });

    it('should render text tooltip placement for <span>', function () {
      expect(this.userAvatarLink.$el.querySelector('span').getAttribute('tooltip-placement')).toEqual(this.propsData.tooltipPlacement);
    });
  });
});
