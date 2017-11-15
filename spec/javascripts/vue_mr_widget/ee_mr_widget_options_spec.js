import Vue from 'vue';
import mrWidgetOptionsEE from 'ee/vue_merge_request_widget/mr_widget_options';
import mockData from './mock_data';
import mountComponent from '../helpers/vue_mount_component_helper';

describe('EE mrWidgetOptions', () => {
  let vm;
  let MrWidgetOptions;

  beforeEach(() => {
    // Prevent component mounting
    delete mrWidgetOptionsEE.extends.el;

    MrWidgetOptions = Vue.extend(mrWidgetOptionsEE);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('shouldRenderApprovals', () => {
      it('should return false when no approvals', () => {
        vm = mountComponent(MrWidgetOptions, {
          mrData: {
            ...mockData,
            approvalsRequired: false,
          },
        });
        vm.mr.state = 'readyToMerge';

        expect(vm.shouldRenderApprovals).toBeFalsy();
      });

      it('should return false when in empty state', () => {
        vm = mountComponent(MrWidgetOptions, {
          mrData: {
            ...mockData,
            approvalsRequired: true,
          },
        });
        vm.mr.state = 'nothingToMerge';

        expect(vm.shouldRenderApprovals).toBeFalsy();
      });

      it('should return true when requiring approvals and in non-empty state', () => {
        vm = mountComponent(MrWidgetOptions, {
          mrData: {
            ...mockData,
            approvalsRequired: true,
          },
        });
        vm.mr.state = 'readyToMerge';

        expect(vm.shouldRenderApprovals).toBeTruthy();
      });
    });
  });
});
