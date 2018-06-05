import Vue from 'vue';
import reportIssues from 'ee/vue_shared/security_reports/components/report_issues.vue';
import store from 'ee/vue_shared/security_reports/store';
import mountComponent, { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import {
  codequalityParsedIssues,
} from 'spec/vue_mr_widget/mock_data';
import {
  sastParsedIssues,
  dockerReportParsed,
  parsedDast,
} from '../mock_data';

describe('Report issues', () => {
  let vm;
  let ReportIssues;

  beforeEach(() => {
    ReportIssues = Vue.extend(reportIssues);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('for codequality issues', () => {
    describe('resolved issues', () => {
      beforeEach(() => {
        vm = mountComponent(ReportIssues, {
          issues: codequalityParsedIssues,
          type: 'codequality',
          status: 'success',
        });
      });

      it('should render a list of resolved issues', () => {
        expect(vm.$el.querySelectorAll('.report-block-list li').length).toEqual(codequalityParsedIssues.length);
      });

      it('should render "Fixed" keyword', () => {
        expect(vm.$el.querySelector('.report-block-list li').textContent).toContain('Fixed');
        expect(
          vm.$el.querySelector('.report-block-list li').textContent.replace(/\s+/g, ' ').trim(),
        ).toEqual('Fixed: Insecure Dependency in Gemfile.lock:12');
      });
    });

    describe('unresolved issues', () => {
      beforeEach(() => {
        vm = mountComponent(ReportIssues, {
          issues: codequalityParsedIssues,
          type: 'codequality',
          status: 'failed',
        });
      });

      it('should render a list of unresolved issues', () => {
        expect(vm.$el.querySelectorAll('.report-block-list li').length).toEqual(codequalityParsedIssues.length);
      });

      it('should not render "Fixed" keyword', () => {
        expect(vm.$el.querySelector('.report-block-list li').textContent).not.toContain('Fixed');
      });
    });
  });

  describe('for security issues', () => {
    beforeEach(() => {
      vm = mountComponent(ReportIssues, {
        issues: sastParsedIssues,
        type: 'SAST',
        status: 'failed',
      });
    });

    it('should render a list of unresolved issues', () => {
      expect(vm.$el.querySelectorAll('.report-block-list li').length).toEqual(sastParsedIssues.length);
    });
  });

  describe('with location', () => {
    it('should render location', () => {
      vm = mountComponent(ReportIssues, {
        issues: sastParsedIssues,
        type: 'SAST',
        status: 'failed',
      });

      expect(vm.$el.querySelector('.report-block-list li').textContent).toContain('in');
      expect(vm.$el.querySelector('.report-block-list li a').getAttribute('href')).toEqual(sastParsedIssues[0].urlPath);
    });
  });

  describe('without location', () => {
    it('should not render location', () => {
      vm = mountComponent(ReportIssues, {
        issues: [{
          title: 'foo',
        }],
        type: 'SAST',
        status: 'failed',
      });

      expect(vm.$el.querySelector('.report-block-list li').textContent).not.toContain('in');
      expect(vm.$el.querySelector('.report-block-list li a')).toEqual(null);
    });
  });

  describe('for container scanning issues', () => {
    beforeEach(() => {
      vm = mountComponent(ReportIssues, {
        issues: dockerReportParsed.unapproved,
        type: 'SAST_CONTAINER',
        status: 'failed',
      });
    });

    it('renders severity', () => {
      expect(
        vm.$el.querySelector('.report-block-list li').textContent.trim(),
      ).toContain(dockerReportParsed.unapproved[0].severity);
    });

    it('renders CVE name', () => {
      expect(
        vm.$el.querySelector('.report-block-list button').textContent.trim(),
      ).toEqual(dockerReportParsed.unapproved[0].title);
    });

    it('renders namespace', () => {
      expect(
        vm.$el.querySelector('.report-block-list li').textContent.trim(),
      ).toContain(dockerReportParsed.unapproved[0].path);
      expect(
        vm.$el.querySelector('.report-block-list li').textContent.trim(),
      ).toContain('in');
    });
  });

  describe('for dast issues', () => {
    beforeEach(() => {
      vm = mountComponentWithStore(ReportIssues, { store,
        props: {
          issues: parsedDast,
          type: 'DAST',
          status: 'failed',
        },
      });
    });

    it('renders severity (confidence) and title', () => {
      expect(vm.$el.textContent).toContain(parsedDast[0].title);
      expect(vm.$el.textContent).toContain(`${parsedDast[0].severity} (${parsedDast[0].confidence})`);
    });
  });
});
