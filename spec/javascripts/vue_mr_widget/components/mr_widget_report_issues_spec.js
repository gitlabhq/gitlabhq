import Vue from 'vue';
import mrWidgetCodeQualityIssues from 'ee/vue_merge_request_widget/components/mr_widget_report_issues.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';
import {
  securityParsedIssues,
  codequalityParsedIssues,
  dockerReportParsed,
  parsedDast,
} from '../mock_data';

describe('merge request report issues', () => {
  let vm;
  let MRWidgetCodeQualityIssues;

  beforeEach(() => {
    MRWidgetCodeQualityIssues = Vue.extend(mrWidgetCodeQualityIssues);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('for codequality issues', () => {
    describe('resolved issues', () => {
      beforeEach(() => {
        vm = mountComponent(MRWidgetCodeQualityIssues, {
          issues: codequalityParsedIssues,
          type: 'codequality',
          status: 'success',
        });
      });

      it('should render a list of resolved issues', () => {
        expect(vm.$el.querySelectorAll('.mr-widget-code-quality-list li').length).toEqual(codequalityParsedIssues.length);
      });

      it('should render "Fixed" keyword', () => {
        expect(vm.$el.querySelector('.mr-widget-code-quality-list li').textContent).toContain('Fixed');
        expect(
          vm.$el.querySelector('.mr-widget-code-quality-list li').textContent.replace(/\s+/g, ' ').trim(),
        ).toEqual('Fixed: Insecure Dependency in Gemfile.lock:12');
      });
    });

    describe('unresolved issues', () => {
      beforeEach(() => {
        vm = mountComponent(MRWidgetCodeQualityIssues, {
          issues: codequalityParsedIssues,
          type: 'codequality',
          status: 'failed',
        });
      });

      it('should render a list of unresolved issues', () => {
        expect(vm.$el.querySelectorAll('.mr-widget-code-quality-list li').length).toEqual(codequalityParsedIssues.length);
      });

      it('should not render "Fixed" keyword', () => {
        expect(vm.$el.querySelector('.mr-widget-code-quality-list li').textContent).not.toContain('Fixed');
      });
    });
  });

  describe('for security issues', () => {
    beforeEach(() => {
      vm = mountComponent(MRWidgetCodeQualityIssues, {
        issues: securityParsedIssues,
        type: 'security',
        status: 'failed',
        hasPriority: true,
      });
    });

    it('should render a list of unresolved issues', () => {
      expect(vm.$el.querySelectorAll('.mr-widget-code-quality-list li').length).toEqual(securityParsedIssues.length);
    });

    it('should render priority', () => {
      expect(vm.$el.querySelector('.mr-widget-code-quality-list li').textContent).toContain(securityParsedIssues[0].priority);
    });
  });

  describe('with location', () => {
    it('should render location', () => {
      vm = mountComponent(MRWidgetCodeQualityIssues, {
        issues: securityParsedIssues,
        type: 'security',
        status: 'failed',
      });

      expect(vm.$el.querySelector('.mr-widget-code-quality-list li').textContent).toContain('in');
      expect(vm.$el.querySelector('.mr-widget-code-quality-list li a').getAttribute('href')).toEqual(securityParsedIssues[0].urlPath);
    });
  });

  describe('without location', () => {
    it('should not render location', () => {
      vm = mountComponent(MRWidgetCodeQualityIssues, {
        issues: [{
          name: 'foo',
        }],
        type: 'security',
        status: 'failed',
      });

      expect(vm.$el.querySelector('.mr-widget-code-quality-list li').textContent).not.toContain('in');
      expect(vm.$el.querySelector('.mr-widget-code-quality-list li a')).toEqual(null);
    });
  });

  describe('for docker issues', () => {
    beforeEach(() => {
      vm = mountComponent(MRWidgetCodeQualityIssues, {
        issues: dockerReportParsed.unapproved,
        type: 'docker',
        status: 'failed',
        hasPriority: true,
      });
    });

    it('renders priority', () => {
      expect(
        vm.$el.querySelector('.mr-widget-code-quality-list li').textContent.trim(),
      ).toContain(dockerReportParsed.unapproved[0].priority);
    });

    it('renders CVE link', () => {
      expect(
        vm.$el.querySelector('.mr-widget-code-quality-list a').getAttribute('href'),
      ).toEqual(dockerReportParsed.unapproved[0].nameLink);
      expect(
        vm.$el.querySelector('.mr-widget-code-quality-list a').textContent.trim(),
      ).toEqual(dockerReportParsed.unapproved[0].name);
    });

    it('renders namespace', () => {
      expect(
        vm.$el.querySelector('.mr-widget-code-quality-list li').textContent.trim(),
      ).toContain(dockerReportParsed.unapproved[0].path);
      expect(
        vm.$el.querySelector('.mr-widget-code-quality-list li').textContent.trim(),
      ).toContain('in');
    });
  });

  describe('for dast issues', () => {
    beforeEach(() => {
      vm = mountComponent(MRWidgetCodeQualityIssues, {
        issues: parsedDast,
        type: 'dast',
        status: 'failed',
        hasPriority: true,
      });
    });

    it('renders priority and name', () => {
      expect(vm.$el.textContent).toContain(parsedDast[0].name);
      expect(vm.$el.textContent).toContain(parsedDast[0].priority);
    });
  });
});
