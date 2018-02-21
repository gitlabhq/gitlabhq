import Vue from 'vue';
import reportSummary from '~/pipelines/components/security_reports/sast_report_summary_widget.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';
import { parsedSastIssuesHead } from '../../vue_shared/security_reports/mock_data';

describe('SAST report summary widget', () => {
  let vm;
  let Component;

  beforeEach(() => {
    Component = Vue.extend(reportSummary);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('with vulnerabilities', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        unresolvedIssues: parsedSastIssuesHead,
      });
    });

    it('renders summary text with warning icon', () => {
      expect(vm.$el.textContent.trim().replace(/\s\s+/g, ' ')).toEqual('SAST degraded on 2 security vulnerabilities');
      expect(vm.$el.querySelector('span').classList).toContain('ci-status-icon-warning');
    });
  });

  describe('without vulnerabilities', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
      });
    });

    it('render summary text with success icon', () => {
      expect(vm.$el.textContent.trim().replace(/\s\s+/g, ' ')).toEqual('SAST detected no security vulnerabilities');
      expect(vm.$el.querySelector('span').classList).toContain('ci-status-icon-success');
    });
  });
});
