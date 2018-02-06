import _ from 'underscore';
import Vue from 'vue';
import stage from '~/pipelines/components/stage.vue';

describe('Pipelines stage component', () => {
  let StageComponent;
  let component;

  beforeEach(() => {
    StageComponent = Vue.extend(stage);

    component = new StageComponent({
      propsData: {
        stage: {
          status: {
            group: 'success',
            icon: 'icon_status_success',
            title: 'success',
          },
          dropdown_path: 'foo',
        },
        updateDropdown: false,
      },
    }).$mount();
  });

  it('should render a dropdown with the status icon', () => {
    expect(component.$el.getAttribute('class')).toEqual('dropdown');
    expect(component.$el.querySelector('svg')).toBeDefined();
    expect(component.$el.querySelector('button').getAttribute('data-toggle')).toEqual('dropdown');
  });

  describe('with successfull request', () => {
    const interceptor = (request, next) => {
      next(request.respondWith(JSON.stringify({ html: 'foo' }), {
        status: 200,
      }));
    };

    beforeEach(() => {
      Vue.http.interceptors.push(interceptor);
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(
        Vue.http.interceptors, interceptor,
      );
    });

    it('should render the received data', (done) => {
      component.$el.querySelector('button').click();

      setTimeout(() => {
        expect(
          component.$el.querySelector('.js-builds-dropdown-container ul').textContent.trim(),
        ).toEqual('foo');
        done();
      }, 0);
    });
  });

  describe('when request fails', () => {
    const interceptor = (request, next) => {
      next(request.respondWith(JSON.stringify({}), {
        status: 500,
      }));
    };

    beforeEach(() => {
      Vue.http.interceptors.push(interceptor);
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(
        Vue.http.interceptors, interceptor,
      );
    });

    it('should close the dropdown', () => {
      component.$el.click();

      setTimeout(() => {
        expect(component.$el.classList.contains('open')).toEqual(false);
      }, 0);
    });
  });

  describe('update endpoint correctly', () => {
    const updatedInterceptor = (request, next) => {
      if (request.url === 'bar') {
        next(request.respondWith(JSON.stringify({ html: 'this is the updated content' }), {
          status: 200,
        }));
      }
      next();
    };

    beforeEach(() => {
      Vue.http.interceptors.push(updatedInterceptor);
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(
        Vue.http.interceptors, updatedInterceptor,
      );
    });

    it('should update the stage to request the new endpoint provided', (done) => {
      component.stage = {
        status: {
          group: 'running',
          icon: 'running',
          title: 'running',
        },
        dropdown_path: 'bar',
      };

      Vue.nextTick(() => {
        component.$el.querySelector('button').click();

        setTimeout(() => {
          expect(
            component.$el.querySelector('.js-builds-dropdown-container ul').textContent.trim(),
            ).toEqual('this is the updated content');
          done();
        });
      });
    });
  });
});
