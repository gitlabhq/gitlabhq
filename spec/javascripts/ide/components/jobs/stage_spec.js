import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { createStore } from '~/ide/stores';
import Stage from '~/ide/components/jobs/stage.vue';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';
import { stages, jobs } from '../../mock_data';

describe('IDE pipeline stage', () => {
  const Component = Vue.extend(Stage);
  let vm;
  let mock;
  let stage;

  beforeEach(done => {
    const store = createStore();
    mock = new MockAdapter(axios);

    Vue.set(
      store.state.pipelines,
      'stages',
      stages.map((mappedState, i) => ({
        ...mappedState,
        id: i,
        dropdownPath: mappedState.dropdown_path,
        jobs: [],
        isLoading: false,
        isCollapsed: false,
      })),
    );

    stage = store.state.pipelines.stages[0];

    mock.onGet(stage.dropdownPath).reply(200, {
      latest_statuses: jobs,
    });

    vm = createComponentWithStore(Component, store, {
      stage,
    }).$mount();

    setTimeout(done, 500);
  });

  afterEach(() => {
    vm.$destroy();

    mock.restore();
  });

  it('renders stages details', () => {
    expect(vm.$el.textContent).toContain(vm.stage.name);
  });

  it('renders CI icon', () => {
    expect(vm.$el.querySelector('.ic-status_failed')).not.toBe(null);
  });

  describe('collapsed', () => {
    it('toggles collapse status when clicking header', done => {
      vm.$el.querySelector('.card-header').click();

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.card-body').style.display).toBe('none');

        done();
      });
    });

    it('sets border bottom class when collapsed', done => {
      vm.$el.querySelector('.card-header').click();

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.card-header').classList).toContain('border-bottom-0');

        done();
      });
    });
  });

  it('renders jobs count', () => {
    expect(vm.$el.querySelector('.badge').textContent).toContain('4');
  });

  it('renders loading icon when no jobs and isLoading is true', done => {
    vm.stage.isLoading = true;
    vm.stage.jobs = [];

    vm.$nextTick(() => {
      expect(vm.$el.querySelector('.loading-container')).not.toBe(null);

      done();
    });
  });

  it('renders list of jobs', () => {
    expect(vm.$el.querySelectorAll('.ide-job-item').length).toBe(4);
  });
});
