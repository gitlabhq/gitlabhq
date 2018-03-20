import Vue from 'vue';
import component from 'ee/vue_shared/security_reports/components/sast_issue_body.vue';
import mountComponent from '../../../helpers/vue_mount_component_helper';

describe('sast issue body', () => {
  let vm;

  const Component = Vue.extend(component);

  const sastIssue = {
    cve: 'CVE-2016-9999',
    file: 'Gemfile.lock',
    message: 'Test Information Leak Vulnerability in Action View',
    name: 'Test Information Leak Vulnerability in Action View',
    path: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    tool: 'bundler_audit',
    url:
      'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
    urlPath: '/Gemfile.lock',
    priority: 'Low',
  };

  afterEach(() => {
    vm.$destroy();
  });

  describe('with priority', () => {
    it('renders priority key', () => {
      vm = mountComponent(Component, {
        issue: sastIssue,
      });

      expect(vm.$el.textContent.trim()).toContain(sastIssue.priority);
    });
  });

  describe('without priority', () => {
    it('does not rendere priority key', () => {
      const issueCopy = Object.assign({}, sastIssue);
      delete issueCopy.priority;

      vm = mountComponent(Component, {
        issue: issueCopy,
      });

      expect(vm.$el.textContent.trim()).not.toContain(
        sastIssue.priority,
      );
    });
  });

  describe('name', () => {
    it('renders name', () => {
      vm = mountComponent(Component, {
        issue: sastIssue,
      });

      expect(vm.$el.textContent.trim()).toContain(
        sastIssue.name,
      );
    });
  });

  describe('path', () => {
    it('renders name', () => {
      vm = mountComponent(Component, {
        issue: sastIssue,
      });

      expect(vm.$el.querySelector('a').getAttribute('href')).toEqual(
        sastIssue.urlPath,
      );
      expect(vm.$el.querySelector('a').textContent.trim()).toEqual(
        sastIssue.path,
      );
    });
  });
});
