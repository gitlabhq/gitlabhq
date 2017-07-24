import Vue from 'vue';
import mrWidgetCodeQuality from '~/vue_merge_request_widget/ee/components/mr_widget_code_quality.vue';
import Store from '~/vue_merge_request_widget/ee/stores/mr_widget_store';
import Service from '~/vue_merge_request_widget/ee/services/mr_widget_service';
import mockData, { baseIssues, headIssues } from '../mock_data';

describe('Merge Request Code Quality', () => {
  let vm;
  let MRWidgetCodeQuality;
  let store;
  let mountComponent;
  let service;

  beforeEach(() => {
    MRWidgetCodeQuality = Vue.extend(mrWidgetCodeQuality);
    store = new Store(mockData);
    service = new Service('');
    mountComponent = props => new MRWidgetCodeQuality({ propsData: props }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('when it is loading', () => {
    beforeEach(() => {
      vm = mountComponent({
        mr: store,
        service,
      });
    });

    it('should render loading indicator', () => {
      expect(vm.$el.textContent.trim()).toEqual('Loading codeclimate report.');
    });
  });

  describe('with successfull request', () => {
    const interceptor = (request, next) => {
      if (request.url === 'head.json') {
        next(request.respondWith(JSON.stringify(headIssues), {
          status: 200,
        }));
      }

      if (request.url === 'base.json') {
        next(request.respondWith(JSON.stringify(baseIssues), {
          status: 200,
        }));
      }
    };

    beforeEach(() => {
      Vue.http.interceptors.push(interceptor);

      vm = mountComponent({
        mr: store,
        service,
      });
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
    });

    it('should render provided data', (done) => {
      setTimeout(() => {
        expect(
          vm.$el.querySelector('span:nth-child(2)').textContent.trim(),
        ).toEqual('Code quality improved on 1 point and degraded on 1 point.');
        done();
      }, 0);
    });

    describe('text connector', () => {
      it('should only render information about fixed issues', (done) => {
        setTimeout(() => {
          vm.mr.codeclimateMetrics.newIssues = [];

          Vue.nextTick(() => {
            expect(
              vm.$el.querySelector('span:nth-child(2)').textContent.trim(),
            ).toEqual('Code quality improved on 1 point.');
            done();
          });
        }, 0);
      });

      it('should only render information about added issues', (done) => {
        setTimeout(() => {
          vm.mr.codeclimateMetrics.resolvedIssues = [];

          Vue.nextTick(() => {
            expect(
              vm.$el.querySelector('span:nth-child(2)').textContent.trim(),
            ).toEqual('Code quality degraded on 1 point.');
            done();
          });
        }, 0);
      });
    });

    describe('toggleCollapsed', () => {
      it('toggles issues', (done) => {
        setTimeout(() => {
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
          done();
        }, 0);
      });
    });
  });

  describe('with empty successfull request', () => {
    const emptyInterceptor = (request, next) => {
      if (request.url === 'head.json') {
        next(request.respondWith(JSON.stringify([]), {
          status: 200,
        }));
      }

      if (request.url === 'base.json') {
        next(request.respondWith(JSON.stringify([]), {
          status: 200,
        }));
      }
    };

    beforeEach(() => {
      Vue.http.interceptors.push(emptyInterceptor);

      vm = mountComponent({
        mr: store,
        service,
      });
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, emptyInterceptor);
    });

    it('should render provided data', (done) => {
      setTimeout(() => {
        expect(
          vm.$el.querySelector('span:nth-child(2)').textContent.trim(),
        ).toEqual('No changes to code quality.');
        done();
      }, 0);
    });
  });

  describe('with failed request', () => {
    const errorInterceptor = (request, next) => {
      if (request.url === 'head.json') {
        next(request.respondWith(JSON.stringify([]), {
          status: 500,
        }));
      }

      if (request.url === 'base.json') {
        next(request.respondWith(JSON.stringify([]), {
          status: 500,
        }));
      }
    };

    beforeEach(() => {
      Vue.http.interceptors.push(errorInterceptor);

      vm = mountComponent({
        mr: store,
        service,
      });
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, errorInterceptor);
    });

    it('should render error indicator', (done) => {
      setTimeout(() => {
        expect(vm.$el.textContent.trim()).toEqual('Failed to load codeclimate report.');
        done();
      }, 0);
    });
  });
});
