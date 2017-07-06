import Vue from 'vue';
import DeployBoard from '~/environments/components/deploy_board_component.vue';
import { deployBoardMockData, invalidDeployBoardMockData } from './mock_data';

describe('Deploy Board', () => {
  let DeployBoardComponent;

  beforeEach(() => {
    DeployBoardComponent = Vue.extend(DeployBoard);
  });

  describe('with valid data', () => {
    let component;

    beforeEach(() => {
      component = new DeployBoardComponent({
        propsData: {
          deployBoardData: deployBoardMockData,
          isLoading: false,
          hasError: false,
        },
      }).$mount();
    });

    it('should render percentage with completion value provided', () => {
      expect(
        component.$el.querySelector('.deploy-board-information .percentage').textContent,
      ).toEqual(`${deployBoardMockData.completion}%`);
    });

    it('should render all instances', () => {
      const instances = component.$el.querySelectorAll('.deploy-board-instances-container div');

      expect(instances.length).toEqual(deployBoardMockData.instances.length);

      expect(
        instances[2].classList.contains(`deploy-board-instance-${deployBoardMockData.instances[2].status}`),
      ).toBe(true);
    });

    it('should render an abort and a rollback button with the provided url', () => {
      const buttons = component.$el.querySelectorAll('.deploy-board-actions a');

      expect(buttons[0].getAttribute('href')).toEqual(deployBoardMockData.rollback_url);
      expect(buttons[1].getAttribute('href')).toEqual(deployBoardMockData.abort_url);
    });
  });

  describe('without valid data', () => {
    let component;

    beforeEach(() => {
      component = new DeployBoardComponent({
        propsData: {
          deployBoardData: invalidDeployBoardMockData,
          isLoading: false,
          hasError: false,
        },
      }).$mount();
    });

    it('should render the empty state', () => {
      expect(component.$el.querySelector('.deploy-board-empty-state-svg svg')).toBeDefined();
      expect(component.$el.querySelector('.deploy-board-empty-state-text .title').textContent).toContain('Kubernetes deployment not found');
    });
  });

  describe('with error', () => {
    let component;

    beforeEach(() => {
      component = new DeployBoardComponent({
        propsData: {
          deployBoardData: {},
          isLoading: false,
          hasError: true,
        },
      }).$mount();
    });

    it('should render empty state', () => {
      expect(component.$el.children.length).toEqual(1);
    });
  });
});
