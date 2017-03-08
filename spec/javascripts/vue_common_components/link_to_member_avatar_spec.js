/* eslint-disable guard-for-in, no-restricted-syntax */
/* global Vue */

require('~/vue_common_component/link_to_member_avatar');

(() => {
  function initComponent(propsData = {}) {
    setFixtures(`
      <div>
        <div id="mock-container"></div>
      </div>
    `);

    const LinkToMembersComponent = Vue.component('link-to-member-avatar');

    this.component = new LinkToMembersComponent({
      el: '#mock-container',
      propsData,
    }).$mount();

    this.$document = $(document);
  }
  describe('Link To Members Components', function () {
    describe('Initialization', function () {
      beforeEach(function () {
        const propsData = this.propsData = {
          avatarSize: 32,
          avatarUrl: 'myavatarurl.com',
          displayName: 'mydisplayname',
          extraAvatarClass: 'myextraavatarclass',
          extraLinkClass: 'myextralinkclass',
          showTooltip: true,
        };
        initComponent.call(this, {
          propsData,
        });
      });

      it('should return a defined Vue component', function () {
        expect(this.component).toBeDefined();
        expect(this.component.$data).toBeDefined();
      });

      it('should have <a> and <img> children', function () {
        const componentLink = this.component.$el.querySelector('a');
        const componentImg = componentLink.querySelector('img');

        expect(componentLink).not.toBeNull();
        expect(componentImg).not.toBeNull();
      });

      it('should correctly compute computed values', function (done) {
        const correctVals = {
          disabledClass: '',
          avatarSizeClass: 's32',
          avatarHtmlClass: 's32 avatar avatar-inline',
          avatarClass: 'avatar avatar-inline s32 ',
          tooltipClass: 'has-tooltip',
          linkClass: 'author_link has-tooltip  ',
          tooltipContainerAttr: 'body',
        };

        Vue.nextTick(() => {
          for (const computedKey in correctVals) {
            const expectedVal = correctVals[computedKey];
            const actualComputed = this.component[computedKey];
            expect(actualComputed).toBe(expectedVal);
          }
          done();
        });
      });
    });
  });
})();
