/* eslint-disable */
//= require jquery
//= require vue_common_component/link_to_member_avatar

((gl) => {
  function initComponent(propsData = {}) {
    fixture.set(`
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
  describe('Link To Members Components', function() {
    describe('Initialization', function() {
      describe('No configuration (defaults)', function() {
        beforeEach(function() {
          initComponent.call(this, { nonUser: true });
        });

        it('should return a defined Vue component', function() {
          expect(this.component).toBeDefined();
          expect(this.component.$data).toBeDefined();
        });

        it('should have <a> and <img> children', function() {
          const componentLink = this.component.$el;
          const componentLinkTagname = componentLink.tagName;

          const componentImg = componentLink.childNodes[0];
          const componentImgTagname = componentImg.tagName;

          expect(componentLink).toBeDefined();
          expect(componentLinkTagname).toBe('A');

          expect(componentImg).toBeDefined();
          expect(componentImgTagname).toBe('IMG');
        });

        it('should correctly compute computed values', function() {
          // disabledclass, avatarClass, tooltipClass, userProfileUrl, preppedAvatarUrl, linkClass, tooltipClass
          const correctVals = {
            'disabledClass': 'disabled',
            'avatarClass': 'avatar avatar-inline s48 ',
            'preppedAvatarUrl': '/assets/no_avatar.png',
            'tooltipClass': '',
            'userProfileUrl': '',
          };

          for (var computedKey in correctVals) {
            const expectedVal = correctVals[computedKey];
            const actualComputed = this.component[computedKey];
            expect(actualComputed).toBe(expectedVal);
          }
        });
      });

      describe('Props Configured', function() {
        beforeEach(function() {
         const propsData = this.propsData = {
            avatarUrl: 'myavatarurl.com',
            username: 'myusername',
            displayName: 'mydisplayname',
            extraAvatarClass: 'myextraavatarclass',
            extraLinkClass: 'myextralinkclass',
            showTooltip: true,
            size: 32,
            nonUser: false
          };
          initComponent.call(this, {
            propsData
          });
        });

        it('should correctly compute computed values', function(done) {
          // disabledclass, avatarClass, tooltipClass, userProfileUrl, preppedAvatarUrl, linkClass, tooltipClass
          const correctVals = {
            'disabledClass': '',
            'avatarClass': 'avatar avatar-inline s48 ',
            'preppedAvatarUrl': this.propsData.avatarUrl,
            'tooltipClass': 'has-tooltip',
            'userProfileUrl': `/${this.propsData.username}`,
          };
          Vue.nextTick(() => {
            for (var computedKey in correctVals) {
              const expectedVal = correctVals[computedKey];
              const actualComputed = this.component[computedKey];
              expect(actualComputed).toBe(expectedVal);
            }
            done();
          });
        });
      });
    });

    describe('Interaction', function() {
      it('should remove approval', function() {

    });
      it('should give approval', function() {

      });
     //  click link and handler fires
    });

  });
})(window.gl || (window.gl = {}));
