import Vue from 'vue';
import mrWidgetCodeQuality from 'ee/vue_merge_request_widget/components/mr_widget_report_collapsible_section.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';
import { codequalityParsedIssues } from '../mock_data';

describe('Merge Request collapsible section', () => {
  let vm;
  let MRWidgetCodeQuality;

  beforeEach(() => {
    MRWidgetCodeQuality = Vue.extend(mrWidgetCodeQuality);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('when it is loading', () => {
    it('should render loading indicator', () => {
      vm = mountComponent(MRWidgetCodeQuality, {
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
      vm = mountComponent(MRWidgetCodeQuality, {
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
        vm = mountComponent(MRWidgetCodeQuality, {
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
            vm.$el.querySelector('.code-quality-container').getAttribute('style'),
          ).toEqual('');
          expect(
            vm.$el.querySelector('button').textContent.trim(),
          ).toEqual('Collapse');

          vm.$el.querySelector('button').click();

          Vue.nextTick(() => {
            expect(
              vm.$el.querySelector('.code-quality-container').getAttribute('style'),
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
      vm = mountComponent(MRWidgetCodeQuality, {
        type: 'codequality',
        status: 'error',
        loadingText: 'Loading codeclimate report',
        errorText: 'Failed to load codeclimate report',
        successText: 'Code quality improved on 1 point and degraded on 1 point',
      });
      expect(vm.$el.textContent.trim()).toEqual('Failed to load codeclimate report');
    });
  });
});
