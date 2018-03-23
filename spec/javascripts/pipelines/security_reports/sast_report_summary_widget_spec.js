import Vue from 'vue';
import reportSummary from 'ee/pipelines/components/security_reports/report_summary_widget.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('Report summary widget', () => {
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
        sastIssues: 2,
        dependencyScanningIssues: 4,
        hasSast: true,
        hasDependencyScanning: true,
      });
    });

    it('renders summary text with warning icon for sast', () => {
      expect(vm.$el.querySelector('.js-sast-summary').textContent.trim().replace(/\s\s+/g, ' ')).toEqual('SAST detected 2 vulnerabilities');
      expect(vm.$el.querySelector('.js-sast-summary span').classList).toContain('ci-status-icon-warning');
    });

    it('renders summary text with warning icon for dependency scanning', () => {
      expect(vm.$el.querySelector('.js-dss-summary').textContent.trim().replace(/\s\s+/g, ' ')).toEqual('Dependency scanning detected 4 vulnerabilities');
      expect(vm.$el.querySelector('.js-dss-summary span').classList).toContain('ci-status-icon-warning');
    });
  });

  describe('without vulnerabilities', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        hasSast: true,
        hasDependencyScanning: true,
      });
    });

    it('render summary text with success icon for sast', () => {
      expect(vm.$el.querySelector('.js-sast-summary').textContent.trim().replace(/\s\s+/g, ' ')).toEqual('SAST detected no vulnerabilities');
      expect(vm.$el.querySelector('.js-sast-summary span').classList).toContain('ci-status-icon-success');
    });

    it('render summary text with success icon for dependecy scanning', () => {
      expect(vm.$el.querySelector('.js-dss-summary').textContent.trim().replace(/\s\s+/g, ' ')).toEqual('Dependency scanning detected no vulnerabilities');
      expect(vm.$el.querySelector('.js-dss-summary span').classList).toContain('ci-status-icon-success');
    });
  });
});
