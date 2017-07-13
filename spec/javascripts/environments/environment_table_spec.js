import Vue from 'vue';
import environmentTableComp from '~/environments/components/environments_table.vue';
import eventHub from '~/environments/event_hub';
import { deployBoardMockData } from './mock_data';

describe('Environment item', () => {
  let EnvironmentTable;

  beforeEach(() => {
    EnvironmentTable = Vue.extend(environmentTableComp);
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
      },
    }).$mount();

    expect(component.$el.getAttribute('class')).toContain('ci-table');
  });

  it('should render deploy board container when data is provided', () => {
    const mockItem = {
      name: 'review',
      size: 1,
      environment_path: 'url',
      id: 1,
      rollout_status_path: 'url',
      hasDeployBoard: true,
      deployBoardData: deployBoardMockData,
      isDeployBoardVisible: true,
      isLoadingDeployBoard: false,
      hasErrorDeployBoard: false,
    };

    const component = new EnvironmentTable({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        environments: [mockItem],
        canCreateDeployment: true,
        canReadEnvironment: true,
      },
    }).$mount();

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

    eventHub.$on('toggleDeployBoard', (env) => {
      expect(env.id).toEqual(mockItem.id);
    });

    const component = new EnvironmentTable({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        environments: [mockItem],
        canCreateDeployment: true,
        canReadEnvironment: true,
      },
    }).$mount();

    component.$el.querySelector('.deploy-board-icon').click();
  });
});
