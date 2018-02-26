import Vue from 'vue';
import DeployBoardInstance from 'ee/environments/components/deploy_board_instance_component.vue';

describe('Deploy Board Instance', () => {
  let DeployBoardInstanceComponent;

  beforeEach(() => {
    DeployBoardInstanceComponent = Vue.extend(DeployBoardInstance);
  });

  it('should render a div with the correct css status and tooltip data', () => {
    const component = new DeployBoardInstanceComponent({
      propsData: {
        status: 'ready',
        tooltipText: 'This is a pod',
      },
    }).$mount();

    expect(component.$el.classList.contains('deploy-board-instance-ready')).toBe(true);
    expect(component.$el.getAttribute('data-title')).toEqual('This is a pod');
  });

  it('should render a div without tooltip data', () => {
    const component = new DeployBoardInstanceComponent({
      propsData: {
        status: 'deploying',
      },
    }).$mount();

    expect(component.$el.classList.contains('deploy-board-instance-deploying')).toBe(true);
    expect(component.$el.getAttribute('data-title')).toEqual('');
  });

  it('should render a div with canary class when stable prop is provided as false', () => {
    const component = new DeployBoardInstanceComponent({
      propsData: {
        status: 'deploying',
        stable: false,
      },
    }).$mount();

    expect(component.$el.classList.contains('deploy-board-instance-canary')).toBe(true);
  });
});
