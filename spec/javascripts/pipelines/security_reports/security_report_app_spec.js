import Vue from 'vue';
import securityReportApp from 'ee/pipelines/components/security_reports/security_report_app.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { parsedSastIssuesHead } from 'spec/vue_shared/security_reports/mock_data';

describe('Security Report App', () => {
  let vm;
  let Component;

  beforeEach(() => {
    Component = Vue.extend(securityReportApp);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('sast report', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        securityReports: {
          sast: {
            isLoading: false,
            hasError: false,
            newIssues: parsedSastIssuesHead,
            resolvedIssues: [],
            allIssues: [],
          },
          dependencyScanning: {
            isLoading: false,
            hasError: false,
            newIssues: parsedSastIssuesHead,
            resolvedIssues: [],
            allIssues: [],
          },
        },
        hasDependencyScanning: true,
        hasSast: true,
      });
    });

    it('renders the sast report', () => {
      expect(vm.$el.querySelector('.js-sast-widget .js-code-text').textContent.trim()).toEqual('SAST degraded on 2 security vulnerabilities');
      expect(vm.$el.querySelectorAll('.js-sast-widget .js-mr-code-new-issues li').length).toEqual(parsedSastIssuesHead.length);

      const issue = vm.$el.querySelector('.js-sast-widget .js-mr-code-new-issues li').textContent;

      expect(issue).toContain(parsedSastIssuesHead[0].message);
      expect(issue).toContain(parsedSastIssuesHead[0].path);
    });

    it('renders the dependency scanning report', () => {
      expect(vm.$el.querySelector('.js-dependency-scanning-widget .js-code-text').textContent.trim()).toEqual('Dependency scanning degraded on 2 security vulnerabilities');
      expect(vm.$el.querySelectorAll('.js-dependency-scanning-widget .js-mr-code-new-issues li').length).toEqual(parsedSastIssuesHead.length);

      const issue = vm.$el.querySelector('.js-dependency-scanning-widget .js-mr-code-new-issues li').textContent;

      expect(issue).toContain(parsedSastIssuesHead[0].message);
      expect(issue).toContain(parsedSastIssuesHead[0].path);
    });
  });
});
