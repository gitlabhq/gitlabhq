const EnvironmentTable = require('~/environments/components/environments_table');

describe('Environment item', () => {
  preloadFixtures('static/environments/element.html.raw');
  beforeEach(() => {
    loadFixtures('static/environments/element.html.raw');
  });

  it('Should render a table', () => {
    const mockItem = {
      name: 'review',
      size: 3,
      isFolder: true,
      latest: {
        environment_path: 'url',
      },
    };

    const component = new EnvironmentTable({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        environments: [{ mockItem }],
        canCreateDeployment: false,
        canReadEnvironment: true,
      },
    });

    expect(component.$el.tagName).toEqual('TABLE');
  });
});
