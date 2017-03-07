/* global Vue */

require('~/merge_request_widget/approvals/components/approvals_footer');

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
      userCanApprove: false,
      userHasApproved: true,
      approvedBy: [],
      approvalsLeft: 1,
      pendingAvatarSvg: '<svg></svg>',
      checkmarkSvg: '<svg></svg>',
    };

    const ApprovalsFooterComponent = Vue.component('approvals-footer');

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
        expect(this.approvalsFooter.showUnapproveButton).toBe(true);
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
