import Vue from 'vue';
import reportSection from 'ee/vue_shared/security_reports/components/report_section.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { codequalityParsedIssues } from 'spec/vue_mr_widget/mock_data';

describe('Report section', () => {
  let vm;
  let ReportSection;

  beforeEach(() => {
    ReportSection = Vue.extend(reportSection);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('when it is loading', () => {
    it('should render loading indicator', () => {
      vm = mountComponent(ReportSection, {
        type: 'codequality',
        status: 'loading',
        loadingText: 'Loading codeclimate report',
        errorText: 'foo',
        successText: 'Code quality improved on 1 point and degraded on 1 point',
      });
      expect(vm.$el.textContent.trim()).toEqual('Loading codeclimate report');
    });
  });

  describe('with success status', () => {
    it('should render provided data', () => {
      vm = mountComponent(ReportSection, {
        type: 'codequality',
        status: 'success',
        loadingText: 'Loading codeclimate report',
        errorText: 'foo',
        successText: 'Code quality improved on 1 point and degraded on 1 point',
        resolvedIssues: codequalityParsedIssues,
      });

      expect(
        vm.$el.querySelector('.js-code-text').textContent.trim(),
      ).toEqual('Code quality improved on 1 point and degraded on 1 point');

      expect(
        vm.$el.querySelectorAll('.js-mr-code-resolved-issues li').length,
      ).toEqual(codequalityParsedIssues.length);
    });

    describe('toggleCollapsed', () => {
      it('toggles issues', (done) => {
        vm = mountComponent(ReportSection, {
          type: 'codequality',
          status: 'success',
          loadingText: 'Loading codeclimate report',
          errorText: 'foo',
          successText: 'Code quality improved on 1 point and degraded on 1 point',
          resolvedIssues: codequalityParsedIssues,
        });

        vm.$el.querySelector('button').click();

        Vue.nextTick(() => {
          expect(
            vm.$el.querySelector('.report-block-container').getAttribute('style'),
          ).toEqual('');
          expect(
            vm.$el.querySelector('button').textContent.trim(),
          ).toEqual('Collapse');

          vm.$el.querySelector('button').click();

          Vue.nextTick(() => {
            expect(
              vm.$el.querySelector('.report-block-container').getAttribute('style'),
            ).toEqual('display: none;');
            expect(
              vm.$el.querySelector('button').textContent.trim(),
            ).toEqual('Expand');

            done();
          });
        });
      });
    });
  });

  describe('with failed request', () => {
    it('should render error indicator', () => {
      vm = mountComponent(ReportSection, {
        type: 'codequality',
        status: 'error',
        loadingText: 'Loading codeclimate report',
        errorText: 'Failed to load codeclimate report',
        successText: 'Code quality improved on 1 point and degraded on 1 point',
      });
      expect(vm.$el.textContent.trim()).toEqual('Failed to load codeclimate report');
    });
  });

  describe('With full report', () => {
    beforeEach(() => {
      vm = mountComponent(ReportSection, {
        status: 'success',
        successText: 'SAST improved on 1 security vulnerability and degraded on 1 security vulnerability',
        type: 'SAST',
        errorText: 'Failed to load security report',
        hasPriority: true,
        loadingText: 'Loading security report',
        resolvedIssues: [{
          cve: 'CVE-2016-9999',
          file: 'Gemfile.lock',
          message: 'Test Information Leak Vulnerability in Action View',
          name: 'Test Information Leak Vulnerability in Action View',
          path: 'Gemfile.lock',
          solution: 'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
          tool: 'bundler_audit',
          url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
          urlPath: '/Gemfile.lock',
        }],
        unresolvedIssues: [{
          cve: 'CVE-2014-7829',
          file: 'Gemfile.lock',
          message: 'Arbitrary file existence disclosure in Action Pack',
          name: 'Arbitrary file existence disclosure in Action Pack',
          path: 'Gemfile.lock',
          solution: 'upgrade to ~> 3.2.21, ~> 4.0.11.1, ~> 4.0.12, ~> 4.1.7.1, >= 4.1.8',
          tool: 'bundler_audit',
          url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
          urlPath: '/Gemfile.lock',
        }],
        allIssues: [{
          cve: 'CVE-2016-0752',
          file: 'Gemfile.lock',
          message: 'Possible Information Leak Vulnerability in Action View',
          name: 'Possible Information Leak Vulnerability in Action View',
          path: 'Gemfile.lock',
          solution: 'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
          tool: 'bundler_audit',
          url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
          urlPath: '/Gemfile.lock',
        }],
      });
    });

    it('should render full report section', (done) => {
      vm.$el.querySelector('button').click();

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelector('.js-expand-full-list').textContent.trim(),
        ).toEqual('Show complete code vulnerabilities report');

        done();
      });
    });

    it('should expand full list when clicked and hide the show all button', (done) => {
      vm.$el.querySelector('button').click();

      Vue.nextTick(() => {
        vm.$el.querySelector('.js-expand-full-list').click();

        Vue.nextTick(() => {
          expect(
            vm.$el.querySelector('.js-mr-code-all-issues').textContent.trim(),
          ).toContain('Possible Information Leak Vulnerability in Action View');

          done();
        });
      });
    });
  });

  describe('When it is not collapsible', () => {
    beforeEach(() => {
      vm = mountComponent(ReportSection, {
        type: 'codequality',
        status: 'success',
        loadingText: 'Loading codeclimate report',
        errorText: 'foo',
        successText: 'Code quality improved on 1 point and degraded on 1 point',
        resolvedIssues: codequalityParsedIssues,
        isCollapsible: false,
      });
    });

    it('should not render collapse button', () => {
      expect(vm.$el.querySelector('.js-collapse-btn')).toBe(null);
    });

    it('should show the report by default', () => {
      expect(
        vm.$el.querySelectorAll('.report-block-list .report-block-list-issue').length,
      ).toEqual(codequalityParsedIssues.length);
    });
  });
});
