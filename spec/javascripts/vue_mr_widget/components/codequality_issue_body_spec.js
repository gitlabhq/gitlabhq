import Vue from 'vue';
import component from 'ee/vue_merge_request_widget/components/codequality_issue_body.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('sast issue body', () => {
  let vm;

  const Component = Vue.extend(component);
  const codequalityIssue = {
    name:
      'rubygem-rest-client: session fixation vulnerability via Set-Cookie headers in 30x redirection responses',
    path: 'Gemfile.lock',
    severity: 'normal',
    type: 'Issue',
    urlPath: '/Gemfile.lock#L22',
  };
  afterEach(() => {
    vm.$destroy();
  });

  describe('with success', () => {
    it('renders fixed label', () => {
      vm = mountComponent(Component, {
        issue: codequalityIssue,
        isStatusSuccess: true,
      });

      expect(vm.$el.textContent.trim()).toContain('Fixed');
    });
  });

  describe('without success', () => {
    it('renders fixed label', () => {
      vm = mountComponent(Component, {
        issue: codequalityIssue,
        isStatusSuccess: false,
      });

      expect(vm.$el.textContent.trim()).not.toContain('Fixed');
    });
  });

  describe('name', () => {
    it('renders name', () => {
      vm = mountComponent(Component, {
        issue: codequalityIssue,
        isStatusSuccess: false,
      });

      expect(vm.$el.textContent.trim()).toContain(codequalityIssue.name);
    });
  });

  describe('path', () => {
    it('renders name', () => {
      vm = mountComponent(Component, {
        issue: codequalityIssue,
        isStatusSuccess: false,
      });

      expect(vm.$el.querySelector('a').getAttribute('href')).toEqual(
        codequalityIssue.urlPath,
      );
      expect(vm.$el.querySelector('a').textContent.trim()).toEqual(
        codequalityIssue.path,
      );
    });
  });
});
