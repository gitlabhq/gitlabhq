import Vue from 'vue';
import environmentTableComp from '~/environments/components/environments_table.vue';

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

    const EnvironmentTable = Vue.extend(environmentTableComp);

    const component = new EnvironmentTable({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        environments: [{ mockItem }],
        canCreateDeployment: false,
        canReadEnvironment: true,
        service: {},
      },
    }).$mount();

    expect(component.$el.tagName).toEqual('TABLE');
  });
});
