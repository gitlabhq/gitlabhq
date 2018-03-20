import Vue from 'vue';
import reportIssues from 'ee/vue_shared/security_reports/components/report_issues.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
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
          name: 'foo',
        }],
        type: 'SAST',
        status: 'failed',
      });

      expect(vm.$el.querySelector('.report-block-list li').textContent).not.toContain('in');
      expect(vm.$el.querySelector('.report-block-list li a')).toEqual(null);
    });
  });

  describe('for docker issues', () => {
    beforeEach(() => {
      vm = mountComponent(ReportIssues, {
        issues: dockerReportParsed.unapproved,
        type: 'SAST_CONTAINER',
        status: 'failed',
      });
    });

    it('renders priority', () => {
      expect(
        vm.$el.querySelector('.report-block-list li').textContent.trim(),
      ).toContain(dockerReportParsed.unapproved[0].priority);
    });

    it('renders CVE link', () => {
      expect(
        vm.$el.querySelector('.report-block-list a').getAttribute('href'),
      ).toEqual(dockerReportParsed.unapproved[0].nameLink);
      expect(
        vm.$el.querySelector('.report-block-list a').textContent.trim(),
      ).toEqual(dockerReportParsed.unapproved[0].name);
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
      vm = mountComponent(ReportIssues, {
        issues: parsedDast,
        type: 'DAST',
        status: 'failed',
      });
    });

    it('renders priority and name', () => {
      expect(vm.$el.textContent).toContain(parsedDast[0].name);
      expect(vm.$el.textContent).toContain(parsedDast[0].priority);
    });

    it('opens modal with more information and list of instances', (done) => {
      vm.$el.querySelector('.js-modal-dast').click();

      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.modal-title').textContent.trim()).toEqual('Low (Medium): Absence of Anti-CSRF Tokens');
        expect(vm.$el.querySelector('.modal-body').textContent).toContain('No Anti-CSRF tokens were found in a HTML submission form.');

        const instance = vm.$el.querySelector('.modal-body li').textContent;
        expect(instance).toContain('http://192.168.32.236:3001/explore?sort=latest_activity_desc');
        expect(instance).toContain('GET');

        done();
      });
    });
  });
});
