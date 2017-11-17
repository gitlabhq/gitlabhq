import Vue from 'vue';
import mrWidgetOptions from 'ee/vue_merge_request_widget/mr_widget_options';
import MRWidgetService from 'ee/vue_merge_request_widget/services/mr_widget_service';
import MRWidgetStore from 'ee/vue_merge_request_widget/stores/mr_widget_store';
import mockData, { baseIssues, headIssues, securityIssues } from './mock_data';
import mountComponent from '../helpers/vue_mount_component_helper';

describe('ee merge request widget options', () => {
  let vm;
  let Component;

  beforeEach(() => {
    delete mrWidgetOptions.extends.el; // Prevent component mounting

    Component = Vue.extend(mrWidgetOptions);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('security widget', () => {
    beforeEach(() => {
      gl.mrWidgetData = {
        ...mockData,
        sast: {
          path: 'path.json',
          blob_path: 'blob_path',
        },
      };

      Component.mr = new MRWidgetStore(gl.mrWidgetData);
      Component.service = new MRWidgetService({});
    });

    describe('when it is loading', () => {
      it('should render loading indicator', () => {
        vm = mountComponent(Component);
        expect(
          vm.$el.querySelector('.js-sast-widget').textContent.trim(),
        ).toContain('Loading security report');
      });
    });

    describe('with successful request', () => {
      const interceptor = (request, next) => {
        if (request.url === 'path.json') {
          next(request.respondWith(JSON.stringify(securityIssues), {
            status: 200,
          }));
        }
      };

      beforeEach(() => {
        Vue.http.interceptors.push(interceptor);
        vm = mountComponent(Component);
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
      });

      it('should render provided data', (done) => {
        setTimeout(() => {
          expect(
            vm.$el.querySelector('.js-sast-widget .js-code-text').textContent.trim(),
          ).toEqual('2 security vulnerabilities detected');
          done();
        }, 0);
      });
    });

    describe('with empty successful request', () => {
      const emptyInterceptor = (request, next) => {
        if (request.url === 'path.json') {
          next(request.respondWith(JSON.stringify([]), {
            status: 200,
          }));
        }
      };

      beforeEach(() => {
        Vue.http.interceptors.push(emptyInterceptor);
        vm = mountComponent(Component);
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(Vue.http.interceptors, emptyInterceptor);
      });

      it('should render provided data', (done) => {
        setTimeout(() => {
          expect(
            vm.$el.querySelector('.js-sast-widget .js-code-text').textContent.trim(),
          ).toEqual('No security vulnerabilities detected');
          done();
        }, 0);
      });
    });

    describe('with failed request', () => {
      const errorInterceptor = (request, next) => {
        if (request.url === 'path.json') {
          next(request.respondWith(JSON.stringify([]), {
            status: 500,
          }));
        }
      };

      beforeEach(() => {
        Vue.http.interceptors.push(errorInterceptor);
        vm = mountComponent(Component);
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(Vue.http.interceptors, errorInterceptor);
      });

      it('should render error indicator', (done) => {
        setTimeout(() => {
          expect(
            vm.$el.querySelector('.js-sast-widget').textContent.trim(),
          ).toContain('Failed to load security report');
          done();
        }, 0);
      });
    });
  });

  describe('code quality', () => {
    beforeEach(() => {
      gl.mrWidgetData = {
        ...mockData,
        codeclimate: {
          head_path: 'head.json',
          base_path: 'base.json',
        },
      };

      Component.mr = new MRWidgetStore(gl.mrWidgetData);
      Component.service = new MRWidgetService({});
    });

    describe('when it is loading', () => {
      it('should render loading indicator', () => {
        vm = mountComponent(Component);
        expect(
          vm.$el.querySelector('.js-codequality-widget').textContent.trim(),
        ).toContain('Loading codeclimate report');
      });
    });

    describe('with successful request', () => {
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
        vm = mountComponent(Component);
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
      });

      it('should render provided data', (done) => {
        setTimeout(() => {
          expect(
            vm.$el.querySelector('.js-code-text').textContent.trim(),
          ).toEqual('Code quality improved on 1 point and degraded on 1 point');
          done();
        }, 0);
      });

      describe('text connector', () => {
        it('should only render information about fixed issues', (done) => {
          setTimeout(() => {
            vm.mr.codeclimateMetrics.newIssues = [];

            Vue.nextTick(() => {
              expect(
                vm.$el.querySelector('.js-code-text').textContent.trim(),
              ).toEqual('Code quality improved on 1 point');
              done();
            });
          }, 0);
        });

        it('should only render information about added issues', (done) => {
          setTimeout(() => {
            vm.mr.codeclimateMetrics.resolvedIssues = [];
            Vue.nextTick(() => {
              expect(
                vm.$el.querySelector('.js-code-text').textContent.trim(),
              ).toEqual('Code quality degraded on 1 point');
              done();
            });
          }, 0);
        });
      });
    });

    describe('with empty successful request', () => {
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
        vm = mountComponent(Component);
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(Vue.http.interceptors, emptyInterceptor);
      });

      it('should render provided data', (done) => {
        setTimeout(() => {
          expect(
            vm.$el.querySelector('.js-code-text').textContent.trim(),
          ).toEqual('No changes to code quality');
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
        vm = mountComponent(Component);
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(Vue.http.interceptors, errorInterceptor);
      });

      it('should render error indicator', (done) => {
        setTimeout(() => {
          expect(vm.$el.querySelector('.js-codequality-widget').textContent.trim()).toContain('Failed to load codeclimate report');
          done();
        }, 0);
      });
    });
  });

  describe('computed', () => {
    describe('shouldRenderApprovals', () => {
      it('should return false when no approvals', () => {
        vm = mountComponent(Component, {
          mrData: {
            ...mockData,
            approvalsRequired: false,
          },
        });
        vm.mr.state = 'readyToMerge';

        expect(vm.shouldRenderApprovals).toBeFalsy();
      });

      it('should return false when in empty state', () => {
        vm = mountComponent(Component, {
          mrData: {
            ...mockData,
            approvalsRequired: true,
          },
        });
        vm.mr.state = 'nothingToMerge';

        expect(vm.shouldRenderApprovals).toBeFalsy();
      });

      it('should return true when requiring approvals and in non-empty state', () => {
        vm = mountComponent(Component, {
          mrData: {
            ...mockData,
            approvalsRequired: true,
          },
        });
        vm.mr.state = 'readyToMerge';

        expect(vm.shouldRenderApprovals).toBeTruthy();
      });
    });
  });
});
