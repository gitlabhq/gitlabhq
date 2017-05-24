import Vue from 'vue';
import DeployBoard from '~/environments/components/deploy_board_component.vue';
import Service from '~/environments/services/environments_service';
import { deployBoardMockData, invalidDeployBoardMockData } from './mock_data';

describe('Deploy Board', () => {
  let DeployBoardComponent;

  beforeEach(() => {
    DeployBoardComponent = Vue.extend(DeployBoard);
  });

  describe('successfull request', () => {
    const deployBoardInterceptor = (request, next) => {
      next(request.respondWith(JSON.stringify(deployBoardMockData), {
        status: 200,
      }));
    };

    let component;

    beforeEach(() => {
      Vue.http.interceptors.push(deployBoardInterceptor);

      this.service = new Service('environments');

      component = new DeployBoardComponent({
        propsData: {
          store: {},
          service: this.service,
          deployBoardData: deployBoardMockData,
          environmentID: 1,
          endpoint: 'endpoint',
        },
      }).$mount();
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(
        Vue.http.interceptors, deployBoardInterceptor,
      );
    });

    it('should render percentage with completion value provided', (done) => {
      setTimeout(() => {
        expect(
          component.$el.querySelector('.deploy-board-information .percentage').textContent,
        ).toEqual(`${deployBoardMockData.completion}%`);

        done();
      }, 0);
    });

    it('should render all instances', (done) => {
      setTimeout(() => {
        const instances = component.$el.querySelectorAll('.deploy-board-instances-container div');

        expect(instances.length).toEqual(deployBoardMockData.instances.length);

        expect(
          instances[2].classList.contains(`deploy-board-instance-${deployBoardMockData.instances[2].status}`),
        ).toBe(true);

        done();
      }, 0);
    });

    it('should render an abort and a rollback button with the provided url', (done) => {
      setTimeout(() => {
        const buttons = component.$el.querySelectorAll('.deploy-board-actions a');

        expect(buttons[0].getAttribute('href')).toEqual(deployBoardMockData.rollback_url);
        expect(buttons[1].getAttribute('href')).toEqual(deployBoardMockData.abort_url);

        done();
      }, 0);
    });
  });

  describe('successfull request without valid data', () => {
    const deployBoardInterceptorInvalidData = (request, next) => {
      next(request.respondWith(JSON.stringify(invalidDeployBoardMockData), {
        status: 200,
      }));
    };

    let component;

    beforeEach(() => {
      Vue.http.interceptors.push(deployBoardInterceptorInvalidData);

      this.service = new Service('environments');

      component = new DeployBoardComponent({
        propsData: {
          store: {},
          service: new Service('environments'),
          deployBoardData: invalidDeployBoardMockData,
          environmentID: 1,
          endpoint: 'endpoint',
        },
      }).$mount();
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(
        Vue.http.interceptors, deployBoardInterceptorInvalidData,
      );
    });

    it('should render the empty state', (done) => {
      setTimeout(() => {
        expect(component.$el.querySelector('.deploy-board-empty-state-svg svg')).toBeDefined();
        expect(component.$el.querySelector('.deploy-board-empty-state-text .title').textContent).toContain('Kubernetes deployment not found');
        done();
      }, 0);
    });
  });

  describe('unsuccessfull request', () => {
    const deployBoardErrorInterceptor = (request, next) => {
      next(request.respondWith(JSON.stringify({}), {
        status: 500,
      }));
    };

    let component;

    beforeEach(() => {
      Vue.http.interceptors.push(deployBoardErrorInterceptor);

      this.service = new Service('environments');

      component = new DeployBoardComponent({
        propsData: {
          store: {},
          service: this.service,
          deployBoardData: {},
          environmentID: 1,
          endpoint: 'endpoint',
        },
      }).$mount();
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, deployBoardErrorInterceptor);
    });

    it('should render empty state', (done) => {
      setTimeout(() => {
        expect(component.$el.children.length).toEqual(1);
        done();
      }, 0);
    });
  });
});
