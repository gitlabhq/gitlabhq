import Vue from 'vue';
import _ from 'underscore';
import ApprovalsBody from 'ee/vue_merge_request_widget/components/approvals/approvals_body';

(() => {
  gl.ApprovalsStore = {
    data: {},
    initStoreOnce() {
      return {
        then() {},
      };
    },
  };

  function initApprovalsBodyComponent() {
    setFixtures(`
      <div>
        <div id="mock-container"></div>
      </div>
    `);

    this.initialData = {
      mr: {},
      service: {},
      suggestedApprovers: [{ name: 'Approver 1' }],
      userCanApprove: false,
      userHasApproved: true,
      approvedBy: [],
      approvalsLeft: 1,
      pendingAvatarSvg: '<svg></svg>',
      checkmarkSvg: '<svg></svg>',
    };

    const ApprovalsBodyComponent = Vue.extend(ApprovalsBody);

    this.approvalsBody = new ApprovalsBodyComponent({
      el: '#mock-container',
      propsData: this.initialData,
    });
  }

  describe('Approvals Body Component', function () {
    beforeEach(function () {
      initApprovalsBodyComponent.call(this);
    });

    it('should correctly set component props', function () {
      const approvalsBody = this.approvalsBody;
      _.each(approvalsBody, (propValue, propKey) => {
        if (this.initialData[propKey]) {
          expect(approvalsBody[propKey]).toBe(this.initialData[propKey]);
        }
      });
    });

    describe('Computed properties', function () {
      describe('approvalsRequiredStringified', function () {
        it('should display the correct string for 1 possible approver', function () {
          const correctText = '1 more approval';
          expect(this.approvalsBody.approvalsRequiredStringified).toBe(correctText);
        });

        it('should display the correct string for 2 possible approvers', function (done) {
          this.approvalsBody.approvalsLeft = 2;
          this.approvalsBody.suggestedApprovers.push({ name: 'Approver 2' });

          Vue.nextTick(() => {
            const correctText = '2 more approvals';
            expect(this.approvalsBody.approvalsRequiredStringified).toBe(correctText);
            done();
          });
        });
      });

      describe('showApproveButton', function () {
        it('should not be true when the user cannot approve', function (done) {
          this.approvalsBody.userCanApprove = false;
          this.approvalsBody.userHasApproved = true;
          Vue.nextTick(() => {
            expect(this.approvalsBody.showApproveButton).toBe(false);
            done();
          });
        });

        it('should be true when the user can approve', function (done) {
          this.approvalsBody.userCanApprove = true;
          this.approvalsBody.userHasApproved = false;
          Vue.nextTick(() => {
            expect(this.approvalsBody.showApproveButton).toBe(true);
            done();
          });
        });
      });
    });
  });
})(window.gl || (window.gl = {}));
