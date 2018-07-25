import Vue from 'vue';
import linkToMemberAvatar from 'ee/vue_shared/components/link_to_member_avatar.vue';

describe('Link To Members Components', () => {
  let vm;
  const propsData = {
    avatarSize: 32,
    avatarUrl: 'myavatarurl.com',
    profileUrl: 'profileUrl.com',
    displayName: 'mydisplayname',
    extraAvatarClass: 'myextraavatarclass',
    extraLinkClass: 'myextralinkclass',
    showTooltip: true,
  };

  beforeEach(() => {
    setFixtures('<div id="mock-container"></div>');

    const LinkToMembersComponent = Vue.extend(linkToMemberAvatar);

    vm = new LinkToMembersComponent({
      el: '#mock-container',
      propsData,
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should default to the body as tooltip container', () => {
    expect(vm.tooltipContainer).toBe('body');
  });

  it('should return a defined Vue component', () => {
    expect(vm).toBeDefined();
    expect(vm.$data).toBeDefined();
  });

  it('should have <a> children', () => {
    const componentLink = vm.$el.querySelector('a');

    expect(componentLink).not.toBeNull();
    expect(componentLink.getAttribute('href')).toBe(propsData.profileUrl);
  });

  it('should show a <img> if the avatarUrl is set', () => {
    const avatarImg = vm.$el.querySelector('a img');

    expect(avatarImg).not.toBeNull();
    expect(avatarImg.getAttribute('src')).toBe(propsData.avatarUrl);
  });

  it('should fallback to a <svg> if the avatarUrl is not set', done => {
    vm.avatarUrl = undefined;

    Vue.nextTick(() => {
      const avatarImg = vm.$el.querySelector('a svg');

      expect(avatarImg).not.toBeNull();
      done();
    });
  });

  it('should correctly compute computed values', () => {
    const correctVals = {
      disabledClass: '',
      avatarSizeClass: 's32',
      avatarHtmlClass: 's32 avatar avatar-inline avatar-placeholder',
      avatarClass: 'avatar avatar-inline s32 myextraavatarclass',
      tooltipClass: 'has-tooltip',
      linkClass: 'author-link has-tooltip myextralinkclass ',
    };

    Object.keys(correctVals).forEach(computedKey => {
      const expectedVal = correctVals[computedKey];
      const actualComputed = vm[computedKey];
      expect(actualComputed).toBe(expectedVal);
    });
  });
});
