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
      mr: {
        isOpen: true,
      },
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

  describe('Approvals Body Component', function() {
    beforeEach(function() {
      initApprovalsBodyComponent.call(this);
    });

    it('should correctly set component props', function() {
      const approvalsBody = this.approvalsBody;
      _.each(approvalsBody, (propValue, propKey) => {
        if (this.initialData[propKey]) {
          expect(approvalsBody[propKey]).toBe(this.initialData[propKey]);
        }
      });
    });

    describe('Computed properties', function() {
      describe('approvalsRequiredStringified', function() {
        it('should display the correct string for 1 possible approver', function() {
          const correctText = 'Requires 1 more approval by';
          expect(this.approvalsBody.approvalsRequiredStringified).toBe(correctText);
        });

        it('should display the correct string for 2 possible approvers', function(done) {
          this.approvalsBody.approvalsLeft = 2;
          this.approvalsBody.suggestedApprovers.push({ name: 'Approver 2' });

          Vue.nextTick(() => {
            const correctText = 'Requires 2 more approvals by';
            expect(this.approvalsBody.approvalsRequiredStringified).toBe(correctText);
            done();
          });
        });

        it('shows the "Approved" text message when there is enough approvals in place', function(done) {
          this.approvalsBody.approvalsLeft = 0;

          Vue.nextTick(() => {
            expect(this.approvalsBody.approvalsRequiredStringified).toBe('Approved');
            done();
          });
        });

        it('shows the "Requires 1 more approval" without by when no suggested approvals are available', function(done) {
          const correctText = 'Requires 1 more approval';
          this.approvalsBody.suggestedApprovers = [];

          Vue.nextTick(() => {
            expect(this.approvalsBody.approvalsRequiredStringified).toBe(correctText);
            done();
          });
        });
      });

      describe('showApproveButton', function() {
        it('should not be true when the user cannot approve', function(done) {
          this.approvalsBody.userCanApprove = false;
          this.approvalsBody.userHasApproved = true;
          Vue.nextTick(() => {
            expect(this.approvalsBody.showApproveButton).toBe(false);
            done();
          });
        });

        it('should be true when the user can approve', function(done) {
          this.approvalsBody.userCanApprove = true;
          this.approvalsBody.userHasApproved = false;
          Vue.nextTick(() => {
            expect(this.approvalsBody.showApproveButton).toBe(true);
            done();
          });
        });
      });

      describe('approveButtonText', function() {
        it('The approve button should have the "Approve" text', function(done) {
          this.approvalsBody.approvalsLeft = 1;
          this.approvalsBody.userHasApproved = false;
          this.approvalsBody.userCanApprove = true;

          Vue.nextTick(() => {
            expect(this.approvalsBody.approveButtonText).toBe('Approve');
            done();
          });
        });

        it('The approve button should have the "Add approval" text', function(done) {
          this.approvalsBody.approvalsLeft = 0;
          this.approvalsBody.userHasApproved = false;
          this.approvalsBody.userCanApprove = true;

          Vue.nextTick(() => {
            expect(this.approvalsBody.approveButtonText).toBe('Add approval');
            done();
          });
        });
      });
    });
  });
})(window.gl || (window.gl = {}));
