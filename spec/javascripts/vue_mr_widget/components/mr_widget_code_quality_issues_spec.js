import Vue from 'vue';
import mrWidgetCodeQualityIssues from '~/vue_merge_request_widget/components/mr_widget_code_quality_issues.vue';

describe('Merge Request Code Quality Issues', () => {
  let vm;
  let MRWidgetCodeQualityIssues;

  beforeEach(() => {
    MRWidgetCodeQualityIssues = Vue.extend(mrWidgetCodeQualityIssues);
  });

  const mountComponent = props => new MRWidgetCodeQualityIssues({ propsData: props }).$mount();

  describe('Renders provided list of issues', () => {
    describe('with positions and lines', () => {
      beforeEach(() => {
        vm = mountComponent({
          title: 'foo',
          issues: [{
            check_name: 'foo',
            location: {
              path: 'bar',
              positions: '81',
              lines: '21',
            },
          }],
        });
      });

      it('should render issue name', () => {
        expect(vm.$el.querySelector('.js-issue-name').textContent.trim()).toEqual('foo');
      });

      it('should render issue location', () => {
        expect(vm.$el.querySelector('.js-issue-location').textContent.trim()).toEqual('bar');
      });

      it('should render issue position', () => {
        expect(vm.$el.querySelector('.js-issue-position').textContent.trim()).toEqual('81');
      });

      it('should render issue lines', () => {
        expect(vm.$el.querySelector('.js-issue-lines').textContent.trim()).toEqual('21');
      });
    });

    describe('without positions and lines', () => {
      beforeEach(() => {
        vm = mountComponent({
          title: 'foo',
          issues: [{
            check_name: 'foo',
            location: {
              path: 'bar',
            },
          }],
        });
      });

      it('should render issue position', () => {
        expect(vm.$el.querySelector('.js-issue-position')).toEqual(null);
      });

      it('should render issue lines', () => {
        expect(vm.$el.querySelector('.js-issue-lines')).toEqual(null);
      });
    });
  });
});
