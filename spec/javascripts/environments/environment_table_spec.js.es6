const EnvironmentTable = require('~/environments/components/environments_table');

describe('Environment item', () => {
  preloadFixtures('static/environments/element.html.raw');
  beforeEach(() => {
    loadFixtures('static/environments/element.html.raw');
  });

  it('Should render a table', () => {
    const mockItem = {
      name: 'review',
      folderName: 'review',
      size: 3,
      isFolder: true,
      environment_path: 'url',
    };

    const component = new EnvironmentTable({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        environments: [mockItem],
        canCreateDeployment: false,
        canReadEnvironment: true,
        toggleDeployBoard: () => {},
        store: {},
        service: {},
      },
    });

    expect(component.$el.tagName).toEqual('TABLE');
  });

  it('should render deploy board container when data is provided', () => {
    const mockItem = {
      name: 'review',
      size: 1,
      environment_path: 'url',
      id: 1,
      rollout_status_path: 'url',
      hasDeployBoard: true,
      deployBoardData: {
        instances: [
          { status: 'ready', tooltip: 'foo' },
        ],
        abort_url: 'url',
        rollback_url: 'url',
        completion: 100,
        is_completed: true,
      },
      isDeployBoardVisible: true,
    };

    const component = new EnvironmentTable({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        environments: [mockItem],
        canCreateDeployment: true,
        canReadEnvironment: true,
        toggleDeployBoard: () => {},
        store: {},
        service: {},
      },
    });

    expect(component.$el.querySelector('.js-deploy-board-row')).toBeDefined();
    expect(
      component.$el.querySelector('.deploy-board-icon i').classList.contains('fa-caret-right'),
    ).toEqual(true);
  });

  it('should toggle deploy board visibility when arrow is clicked', () => {
    const mockItem = {
      name: 'review',
      size: 1,
      environment_path: 'url',
      id: 1,
      rollout_status_path: 'url',
      hasDeployBoard: true,
      deployBoardData: {
        instances: [
          { status: 'ready', tooltip: 'foo' },
        ],
        abort_url: 'url',
        rollback_url: 'url',
        completion: 100,
        is_completed: true,
      },
      isDeployBoardVisible: false,
    };

    const spy = jasmine.createSpy('spy');

    const component = new EnvironmentTable({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        environments: [mockItem],
        canCreateDeployment: true,
        canReadEnvironment: true,
        toggleDeployBoard: spy,
        store: {},
        service: {},
      },
    });

    component.$el.querySelector('.deploy-board-icon').click();

    expect(spy).toHaveBeenCalled();
  });
});
