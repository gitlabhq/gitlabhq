import Vue from 'vue';
import issueWarning from '~/vue_shared/components/issue/issue_warning.vue';
import mountComponent from '../../../helpers/vue_mount_component_helper';

const IssueWarning = Vue.extend(issueWarning);

function formatWarning(string) {
  return string.trim().replace(/\n/g, ' ').replace(/\s\s+/g, ' ');
}

describe('Issue Warning Component', () => {
  describe('if locked', () => {
    it('should render locked issue warning information', () => {
      const vm = mountComponent(IssueWarning, {
        locked: true,
      });

      expect(vm.$el.querySelector('i').className).toEqual('fa fa-lock');
      expect(formatWarning(vm.$el.querySelector('span').textContent)).toEqual('This issue is locked. Only project members can comment.');
    });
  });

  describe('if confidential', () => {
    it('should render confidential issue warning information', () => {
      const vm = mountComponent(IssueWarning, {
        confidential: true,
      });

      expect(vm.$el.querySelector('i').className).toEqual('fa fa-eye-slash');
      expect(formatWarning(vm.$el.querySelector('span').textContent)).toEqual('This is a confidential issue. Your comment will not be visible to the public.');
    });
  });

  describe('if locked and confidential', () => {
    it('should render locked and confidential issue warning information', () => {
      const vm = mountComponent(IssueWarning, {
        locked: true,
        confidential: true,
      });

      expect(vm.$el.querySelector('i')).toBeFalsy();
      expect(formatWarning(vm.$el.querySelector('span').textContent)).toEqual('This issue is confidential and locked. People without permission will never get a notification and not be able to comment.');
    });
  });
});
