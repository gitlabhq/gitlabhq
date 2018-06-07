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
    title: 'Test Information Leak Vulnerability in Action View',
    path: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    tool: 'bundler_audit',
    url:
      'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
    urlPath: '/Gemfile.lock',
    severity: 'Medium',
    confidence: 'Low',
  };

  afterEach(() => {
    vm.$destroy();
  });

  describe('with severity and confidence (new json format)', () => {
    it('renders severity and confidence', () => {
      vm = mountComponent(Component, {
        issue: sastIssue,
      });

      expect(vm.$el.textContent.trim()).toContain(`${sastIssue.severity} (${sastIssue.confidence})`);
    });
  });

  describe('without severity', () => {
    it('does not render severity nor confidence', () => {
      const issueCopy = Object.assign({}, sastIssue);
      delete issueCopy.severity;

      vm = mountComponent(Component, {
        issue: issueCopy,
      });

      expect(vm.$el.textContent.trim()).not.toContain(sastIssue.severity);
      expect(vm.$el.textContent.trim()).not.toContain(sastIssue.confidence);
    });
  });

  describe('with priority (old json format)', () => {
    it('renders priority key', () => {
      const issueCopy = Object.assign({}, sastIssue);
      delete issueCopy.severity;
      delete issueCopy.confidence;
      issueCopy.priority = 'Low';
      vm = mountComponent(Component, {
        issue: issueCopy,
      });

      expect(vm.$el.textContent.trim()).toContain(issueCopy.priority);
    });
  });

  describe('without priority', () => {
    it('does not render priority key', () => {
      const issueCopy = Object.assign({}, sastIssue);
      delete issueCopy.severity;
      delete issueCopy.confidence;

      vm = mountComponent(Component, {
        issue: issueCopy,
      });

      expect(vm.$el.textContent.trim()).not.toContain(
        sastIssue.priority,
      );
    });
  });

  describe('title', () => {
    it('renders title', () => {
      vm = mountComponent(Component, {
        issue: sastIssue,
      });

      expect(vm.$el.textContent.trim()).toContain(
        sastIssue.title,
      );
    });
  });

  describe('path', () => {
    it('renders path', () => {
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
