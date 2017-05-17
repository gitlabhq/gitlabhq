import Vue from 'vue';
import mrWidgetCodeQuality from '~/vue_merge_request_widget/components/mr_widget_code_quality.vue';

describe('Merge Request Code Quality', () => {
  let vm;
  let MRWidgetCodeQuality;

  beforeEach(() => {
    MRWidgetCodeQuality = Vue.extend(mrWidgetCodeQuality);
  });

  afterEach(() => {
    vm.$destroy();
  });

  const mountComponent = props => new MRWidgetCodeQuality({ propsData: props }).$mount();

  describe('when it is loading', () => {
    beforeEach(() => {
      vm = mountComponent({
        isLoading: true,
        loadingFailed: false,
      });
    });

    it('should render loading indicator', () => {
      expect(vm.$el.querySelector('.js-usage-info fa-spinner')).toBeDefined();
    });
  });

  describe('with successfull request', () => {
    const resolvedIssue = {
      check_name: 'foo_resolved',
      location: {
        path: 'bar_resolved',
        positions: '82',
        lines: '22',
      },
    };

    const newIssue = {
      check_name: 'foo',
      location: {
        path: 'bar',
        positions: '81',
        lines: '21',
      },
    };

    describe('with new and resolved issues', () => {
      it('should render provided data', () => {
        vm = mountComponent({
          isLoading: false,
          loadingFailed: false,
          newIssues: [newIssue],
          resolvedIssues: [resolvedIssue],
        });
        expect(
          vm.$el.querySelector('.js-mr-code-new-issues p').textContent.trim(),
        ).toEqual('Issues introduced in this merge request:');

        expect(
          vm.$el.querySelectorAll('.js-mr-code-new-issues li').length,
        ).toEqual(1);

        expect(
          vm.$el.querySelector('.js-mr-code-resolved-issues p').textContent.trim(),
        ).toEqual('Issues resolved in this merge request:');

        expect(
          vm.$el.querySelectorAll('.js-mr-code-resolved-issues li').length,
        ).toEqual(1);
      });
    });
  });

  describe('with failed request', () => {
    beforeEach(() => {
      vm = mountComponent({
        isLoading: false,
        loadingFailed: true,
      });
    });

    it('should render error indicator', () => {
      expect(vm.$el.textContent.trim()).toEqual('Failed to load codeclimate report.');
    });
  });
});
