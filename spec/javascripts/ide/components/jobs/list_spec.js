import Vue from 'vue';
import StageList from '~/ide/components/jobs/list.vue';
import { createStore } from '~/ide/stores';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';
import { stages, jobs } from '../../mock_data';

describe('IDE stages list', () => {
  const Component = Vue.extend(StageList);
  let vm;

  beforeEach(() => {
    const store = createStore();

    vm = createComponentWithStore(Component, store, {
      stages: stages.map((mappedState, i) => ({
        ...mappedState,
        id: i,
        dropdownPath: mappedState.dropdown_path,
        jobs: [...jobs],
        isLoading: false,
        isCollapsed: false,
      })),
      loading: false,
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders list of stages', () => {
    expect(vm.$el.querySelectorAll('.card').length).toBe(2);
  });

  it('renders loading icon when no stages & is loading', done => {
    vm.stages = [];
    vm.loading = true;

    vm.$nextTick(() => {
      expect(vm.$el.querySelector('.loading-container')).not.toBe(null);

      done();
    });
  });
});
