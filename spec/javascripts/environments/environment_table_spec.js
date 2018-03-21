import Vue from 'vue';
import environmentTableComp from '~/environments/components/environments_table.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('Environment table', () => {
  let Component;
  let vm;

  beforeEach(() => {
    Component = Vue.extend(environmentTableComp);
  });

  afterEach(() => {
    vm.$destroy();
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

    vm = mountComponent(Component, {
      environments: [mockItem],
      canCreateDeployment: false,
      canReadEnvironment: true,
    });

    expect(vm.$el.getAttribute('class')).toContain('ci-table');
  });
});
