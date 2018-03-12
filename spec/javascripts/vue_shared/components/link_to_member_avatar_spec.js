/* eslint-disable no-restricted-syntax */

import $ from 'jquery';
import Vue from 'vue';
import linkToMemberAvatar from 'ee/vue_shared/components/link_to_member_avatar';

(() => {
  function initComponent(propsData = {}) {
    setFixtures(`
      <div>
        <div id="mock-container"></div>
      </div>
    `);

    const LinkToMembersComponent = Vue.extend(linkToMemberAvatar);

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

      it('should have <a> and <svg> children', function () {
        const componentLink = this.component.$el.querySelector('a');
        const componentPlaceholder = componentLink.querySelector('svg');

        expect(componentLink).not.toBeNull();
        expect(componentPlaceholder).not.toBeNull();
      });

      it('should correctly compute computed values', function (done) {
        const correctVals = {
          disabledClass: '',
          avatarSizeClass: 's32',
          avatarHtmlClass: 's32 avatar avatar-inline avatar-placeholder',
          avatarClass: 'avatar avatar-inline s32 ',
          tooltipClass: 'has-tooltip',
          linkClass: 'author_link has-tooltip  ',
          tooltipContainerAttr: 'body',
        };

        Vue.nextTick(() => {
          for (const computedKey in correctVals) {
            if (Object.prototype.hasOwnProperty.call(correctVals, computedKey)) {
              const expectedVal = correctVals[computedKey];
              const actualComputed = this.component[computedKey];
              expect(actualComputed).toBe(expectedVal);
            }
          }
          done();
        });
      });
    });
  });
})();
