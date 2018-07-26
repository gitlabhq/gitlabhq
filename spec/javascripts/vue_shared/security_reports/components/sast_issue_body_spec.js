import Vue from 'vue';
import component from 'ee/vue_shared/security_reports/components/sast_issue_body.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { STATUS_FAILED } from '~/vue_shared/components/reports/constants';

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

  const status = STATUS_FAILED;

  afterEach(() => {
    vm.$destroy();
  });

  describe('with severity and confidence (new json format)', () => {
    it('renders severity and confidence', () => {
      vm = mountComponent(Component, {
        issue: sastIssue,
        status,
      });

      expect(vm.$el.textContent.trim()).toContain(`${sastIssue.severity} (${sastIssue.confidence}):`);
    });
  });

  describe('with severity and without confidence (new json format)', () => {
    it('renders severity only', () => {
      const issueCopy = Object.assign({}, sastIssue);
      delete issueCopy.confidence;
      vm = mountComponent(Component, {
        issue: issueCopy,
        status,
      });

      expect(vm.$el.textContent.trim()).toContain(`${issueCopy.severity}:`);
    });
  });

  describe('with confidence and without severity (new json format)', () => {
    it('renders confidence only', () => {
      const issueCopy = Object.assign({}, sastIssue);
      delete issueCopy.severity;
      vm = mountComponent(Component, {
        issue: issueCopy,
        status,
      });

      expect(vm.$el.textContent.trim()).toContain(`(${issueCopy.confidence}):`);
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
        status,
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
        status,
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
        status,
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
        status,
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
