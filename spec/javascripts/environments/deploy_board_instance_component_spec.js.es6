require('vue');
const DeployBoardInstanceComponent = require('~/environments/components/deploy_board_instance_component');

describe('Deploy Board Instance', () => {
  preloadFixtures('static/environments/element.html.raw');

  beforeEach(() => {
    loadFixtures('static/environments/element.html.raw');
  });

  it('should render a div with the correct css status and tooltip data', () => {
    const component = new DeployBoardInstanceComponent({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        status: 'ready',
        tooltipText: 'This is a pod',
      },
    });

    expect(component.$el.classList.contains('deploy-board-instance-ready')).toBe(true);
    expect(component.$el.getAttribute('data-title')).toEqual('This is a pod');
  });

  it('should render a div without tooltip data', () => {
    const component = new DeployBoardInstanceComponent({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        status: 'deploying',
      },
    });

    expect(component.$el.classList.contains('deploy-board-instance-deploying')).toBe(true);
    expect(component.$el.getAttribute('data-title')).toEqual('');
  });
});
