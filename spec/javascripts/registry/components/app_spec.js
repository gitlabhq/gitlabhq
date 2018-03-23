import _ from 'underscore';
import Vue from 'vue';
import registry from '~/registry/components/app.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { reposServerResponse } from '../mock_data';

describe('Registry List', () => {
  let vm;
  let Component;

  beforeEach(() => {
    Component = Vue.extend(registry);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('with data', () => {
    const interceptor = (request, next) => {
      next(request.respondWith(JSON.stringify(reposServerResponse), {
        status: 200,
      }));
    };

    beforeEach(() => {
      Vue.http.interceptors.push(interceptor);
      vm = mountComponent(Component, { endpoint: 'foo' });
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
    });

    it('should render a list of repos', (done) => {
      setTimeout(() => {
        expect(vm.$store.state.repos.length).toEqual(reposServerResponse.length);

        Vue.nextTick(() => {
          expect(
            vm.$el.querySelectorAll('.container-image').length,
          ).toEqual(reposServerResponse.length);
          done();
        });
      }, 0);
    });

    describe('delete repository', () => {
      it('should be possible to delete a repo', (done) => {
        setTimeout(() => {
          Vue.nextTick(() => {
            expect(vm.$el.querySelector('.container-image-head .js-remove-repo')).toBeDefined();
            done();
          });
        }, 0);
      });
    });

    describe('toggle repository', () => {
      it('should open the container', (done) => {
        setTimeout(() => {
          Vue.nextTick(() => {
            vm.$el.querySelector('.js-toggle-repo').click();
            Vue.nextTick(() => {
              expect(vm.$el.querySelector('.js-toggle-repo i').className).toEqual('fa fa-chevron-up');
              done();
            });
          });
        }, 0);
      });
    });
  });

  describe('without data', () => {
    const interceptor = (request, next) => {
      next(request.respondWith(JSON.stringify([]), {
        status: 200,
      }));
    };

    beforeEach(() => {
      Vue.http.interceptors.push(interceptor);
      vm = mountComponent(Component, { endpoint: 'foo' });
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
    });

    it('should render empty message', (done) => {
      setTimeout(() => {
        expect(
          vm.$el.querySelector('p').textContent.trim().replace(/[\r\n]+/g, ' '),
        ).toEqual('No container images stored for this project. Add one by following the instructions above.');
        done();
      }, 0);
    });
  });

  describe('while loading data', () => {
    const interceptor = (request, next) => {
      next(request.respondWith(JSON.stringify(reposServerResponse), {
        status: 200,
      }));
    };

    beforeEach(() => {
      Vue.http.interceptors.push(interceptor);
      vm = mountComponent(Component, { endpoint: 'foo' });
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
    });

    it('should render a loading spinner', (done) => {
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.fa-spinner')).not.toBe(null);
        done();
      });
    });
  });
});
