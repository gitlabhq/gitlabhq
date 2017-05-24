import Vue from 'vue';

import pendingAvatarSvg from 'icons/_icon_dotted_circle.svg';
import ApprovalsFooter from '~/vue_merge_request_widget/ee/components/approvals/approvals_footer';

(() => {
  gl.ApprovalsStore = {
    data: {},
    initStoreOnce() {
      return {
        then() {},
      };
    },
  };

  function initApprovalsFooterComponent() {
    setFixtures(`
      <div>
        <div id="mock-container"></div>
      </div>
    `);

    this.initialData = {
      mr: {
        state: 'readyToMerge',
      },
      service: {},
      userCanApprove: false,
      userHasApproved: true,
      approvedBy: [],
      approvalsLeft: 1,
      pendingAvatarSvg,
    };

    const ApprovalsFooterComponent = Vue.extend(ApprovalsFooter);

    this.approvalsFooter = new ApprovalsFooterComponent({
      el: '#mock-container',
      propsData: this.initialData,
      beforeCreate() {},
    });
  }

  describe('Approvals Footer Component', function () {
    beforeEach(function () {
      initApprovalsFooterComponent.call(this);
    });

    it('should correctly set component props', function () {
      const approvalsFooter = this.approvalsFooter;
      _.each(approvalsFooter, (propValue, propKey) => {
        if (this.initialData[propKey]) {
          expect(approvalsFooter[propKey]).toBe(this.initialData[propKey]);
        }
      });
    });

    describe('Computed properties', function () {
      it('should correctly set showUnapproveButton when the user can unapprove', function () {
        expect(this.approvalsFooter.showUnapproveButton).toBeTruthy();
        this.approvalsFooter.mr.state = 'merged';
        expect(this.approvalsFooter.showUnapproveButton).toBeFalsy();
      });

      it('should correctly set showUnapproveButton when the user can not unapprove', function (done) {
        this.approvalsFooter.userCanApprove = true;

        Vue.nextTick(() => {
          expect(this.approvalsFooter.showUnapproveButton).toBe(false);
          done();
        });
      });
    });
  });
})(window.gl || (window.gl = {}));
