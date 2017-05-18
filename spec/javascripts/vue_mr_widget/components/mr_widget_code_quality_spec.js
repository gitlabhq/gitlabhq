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
      expect(vm.$el.textContent.trim()).toEqual('Loading codeclimate report.');
    });
  });

  describe('with successfull request', () => {
    beforeEach(() => {
      vm = mountComponent({
        isLoading: false,
        loadingFailed: false,
        newIssues: [{
          check_name: 'Insecure Source',
          location: {
            path: 'index.html',
            lines: {
              begin: 10,
              end: 34,
            },
          },
        }],
        resolvedIssues: [{
          check_name: 'Insecure Source',
          location: {
            path: 'Gemfile.lock',
            lines: {
              begin: 2,
              end: 2,
            },
          },
        }],
      });
    });

    it('should render provided data', () => {
      expect(
        vm.$el.querySelector('span:nth-child(2)').textContent.trim(),
      ).toEqual('Code quality improved on 1 point and degraded on 1 point');
    });

    describe('toggleCollapsed', () => {
      it('toggles issues', () => {
        vm.$el.querySelector('button').click();

        Vue.nextTick(() => {
          expect(
            vm.$el.querySelector('.code-quality-container').geAttribute('style'),
          ).toEqual(null);
          expect(
            vm.$el.querySelector('button').textContent.trim(),
          ).toEqual('Collapse');

          vm.$el.querySelector('button').click();

          Vue.nextTick(() => {
            expect(
              vm.$el.querySelector('.code-quality-container').geAttribute('style'),
            ).toEqual('display: none;');
            expect(
              vm.$el.querySelector('button').textContent.trim(),
            ).toEqual('Expand');
          });
        });
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
