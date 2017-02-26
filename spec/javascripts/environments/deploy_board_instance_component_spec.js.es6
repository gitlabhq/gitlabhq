const Vue = require('vue');
const DeployBoardInstance = require('~/environments/components/deploy_board_instance_component');

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
});
