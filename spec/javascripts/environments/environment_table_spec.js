import Vue from 'vue';
import environmentTableComp from '~/environments/components/environments_table.vue';
import eventHub from '~/environments/event_hub';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { deployBoardMockData } from './mock_data';

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
      folderName: 'review',
      size: 3,
      isFolder: true,
      environment_path: 'url',
    };

    vm = mountComponent(Component, {
      environments: [mockItem],
      canCreateDeployment: false,
      canReadEnvironment: true,
    });

    expect(vm.$el.getAttribute('class')).toContain('ci-table');
  });

  it('should render deploy board container when data is provided', () => {
    const mockItem = {
      name: 'review',
      size: 1,
      environment_path: 'url',
      id: 1,
      hasDeployBoard: true,
      deployBoardData: deployBoardMockData,
      isDeployBoardVisible: true,
      isLoadingDeployBoard: false,
      isEmptyDeployBoard: false,
    };

    vm = mountComponent(Component, {
      environments: [mockItem],
      canCreateDeployment: false,
      canReadEnvironment: true,
    });

    expect(vm.$el.querySelector('.js-deploy-board-row')).toBeDefined();
    expect(
      vm.$el.querySelector('.deploy-board-icon i').classList.contains('fa-caret-right'),
    ).toEqual(true);
  });

  it('should toggle deploy board visibility when arrow is clicked', () => {
    const mockItem = {
      name: 'review',
      size: 1,
      environment_path: 'url',
      id: 1,
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

    eventHub.$on('toggleDeployBoard', (env) => {
      expect(env.id).toEqual(mockItem.id);
    });

    vm = mountComponent(Component, {
      environments: [mockItem],
      canCreateDeployment: false,
      canReadEnvironment: true,
    });

    vm.$el.querySelector('.deploy-board-icon').click();
  });
});
