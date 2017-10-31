import Vue from 'vue';
import mrWidgetCodeQualityIssues from 'ee/vue_merge_request_widget/components/mr_widget_code_quality_issues.vue';

describe('merge request code quality issues', () => {
  let vm;
  let MRWidgetCodeQualityIssues;
  let mountComponent;

  beforeEach(() => {
    MRWidgetCodeQualityIssues = Vue.extend(mrWidgetCodeQualityIssues);
    mountComponent = props => new MRWidgetCodeQualityIssues({ propsData: props }).$mount();
  });

  describe('renders provided list of issues', () => {
    describe('with positions and lines', () => {
      beforeEach(() => {
        vm = mountComponent({
          type: 'success',
          issues: [{
            check_name: 'foo',
            location: {
              path: 'bar',
              urlPath: 'foo',
              positions: '81',
              lines: {
                begin: '21',
              },
            },
          }],
        });
      });

      it('should render issue', () => {
        expect(
          vm.$el.querySelector('li').textContent.trim().replace(/\s+/g, ''),
        ).toEqual('Fixed:fooinbar:21');
      });
    });

    describe('for type failed', () => {
      beforeEach(() => {
        vm = mountComponent({
          type: 'failed',
          issues: [{
            check_name: 'foo',
            location: {
              path: 'bar',
              positions: '81',
              lines: {
                begin: '21',
              },
            },
          }],
        });
      });

      it('should render failed minus icon', () => {
        expect(vm.$el.querySelector('li').classList.contains('failed')).toEqual(true);
        expect(vm.$el.querySelector('li svg use').getAttribute('xlink:href')).toContain('cut');
      });
    });

    describe('for type success', () => {
      beforeEach(() => {
        vm = mountComponent({
          type: 'success',
          issues: [{
            check_name: 'foo',
            location: {
              path: 'bar',
              positions: '81',
              lines: {
                begin: '21',
              },
            },
          }],
        });
      });

      it('should render success plus icon', () => {
        expect(vm.$el.querySelector('li').classList.contains('success')).toEqual(true);
        expect(vm.$el.querySelector('li svg use').getAttribute('xlink:href')).toContain('plus');
      });
    });
  });
});
