/* global Vue */

require('~/merge_request_widget/approvals/components/approvals_body');

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
      suggestedApprovers: [{ name: 'Approver 1' }],
      userCanApprove: false,
      userHasApproved: true,
      approvedBy: [],
      approvalsLeft: 1,
      pendingAvatarSvg: '<svg></svg>',
      checkmarkSvg: '<svg></svg>',
    };

    const ApprovalsBodyComponent = Vue.component('approvals-body');

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

        it('should display the correct string for 2 possible approver', function (done) {
          this.approvalsBody.approvalsLeft = 2;
          this.approvalsBody.suggestedApprovers.push({ name: 'Approver 2' });

          Vue.nextTick(() => {
            const correctText = '2 more approvals';
            expect(this.approvalsBody.approvalsRequiredStringified).toBe(correctText);
            done();
          });
        });
      });

      describe('approverNamesStringified', function () {
        // Preceded by: Requires {1 more approval} required from _____
        it('should display the correct string for 1 possible approver name', function (done) {
          const correctText = 'Approver 1';
          Vue.nextTick(() => {
            expect(this.approvalsBody.approverNamesStringified).toBe(correctText);
            done();
          });
        });

        it('should display the correct string for 2 possible approver names', function (done) {
          this.approvalsBody.approvalsLeft = 2;
          this.approvalsBody.suggestedApprovers.push({ name: 'Approver 2' });

          Vue.nextTick(() => {
            const correctText = 'Approver 1 or Approver 2';
            expect(this.approvalsBody.approverNamesStringified).toBe(correctText);
            done();
          });
        });

        it('should display the correct string for 3 possible approver names', function (done) {
          this.approvalsBody.approvalsLeft = 3;
          this.approvalsBody.suggestedApprovers.push({ name: 'Approver 2' });
          this.approvalsBody.suggestedApprovers.push({ name: 'Approver 3' });

          Vue.nextTick(() => {
            const correctText = 'Approver 1, Approver 2 or Approver 3';
            expect(this.approvalsBody.approverNamesStringified).toBe(correctText);
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
