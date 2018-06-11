import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { createStore } from '~/ide/stores';
import List from '~/ide/components/pipelines/list.vue';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';
import { pipelines, projectData, stages, jobs } from '../../mock_data';

describe('IDE pipelines list', () => {
  const Component = Vue.extend(List);
  let vm;
  let mock;

  beforeEach(done => {
    const store = createStore();

    mock = new MockAdapter(axios);

    store.state.currentProjectId = 'abc/def';
    store.state.currentBranchId = 'master';
    store.state.projects['abc/def'] = {
      ...projectData,
      path_with_namespace: 'abc/def',
      branches: {
        master: { commit: { id: '123' } },
      },
    };
    store.state.links = { ciHelpPagePath: gl.TEST_HOST };
    store.state.pipelinesEmptyStateSvgPath = gl.TEST_HOST;
    store.state.pipelines.stages = stages.map((mappedState, i) => ({
      ...mappedState,
      id: i,
      dropdownPath: mappedState.dropdown_path,
      jobs: [...jobs],
      isLoading: false,
      isCollapsed: false,
    }));

    mock
      .onGet('/abc/def/commit/123/pipelines')
      .replyOnce(200, { pipelines: [...pipelines] }, { 'poll-interval': '-1' });

    vm = createComponentWithStore(Component, store).$mount();

    setTimeout(done);
  });

  afterEach(done => {
    vm.$destroy();
    mock.restore();

    vm.$store
      .dispatch('pipelines/stopPipelinePolling')
      .then(() => vm.$store.dispatch('pipelines/clearEtagPoll'))
      .then(done)
      .catch(done.fail);
  });

  it('renders pipeline data', () => {
    expect(vm.$el.textContent).toContain('#1');
  });

  it('renders CI icon', () => {
    expect(vm.$el.querySelector('.ci-status-icon-failed')).not.toBe(null);
  });

  it('renders list of jobs', () => {
    expect(vm.$el.querySelectorAll('.tab-pane:first-child .ide-job-item').length).toBe(
      jobs.length * stages.length,
    );
  });

  it('renders list of failed jobs on failed jobs tab', done => {
    vm.$el.querySelectorAll('.tab-links a')[1].click();

    vm.$nextTick(() => {
      expect(vm.$el.querySelectorAll('.tab-pane.active .ide-job-item').length).toBe(2);

      done();
    });
  });

  describe('YAML error', () => {
    it('renders YAML error', done => {
      vm.$store.state.pipelines.latestPipeline.yamlError = 'test yaml error';

      vm.$nextTick(() => {
        expect(vm.$el.textContent).toContain('Found errors in your .gitlab-ci.yml:');
        expect(vm.$el.textContent).toContain('test yaml error');

        done();
      });
    });
  });

  describe('empty state', () => {
    it('renders pipelines empty state', done => {
      vm.$store.state.pipelines.latestPipeline = false;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.empty-state')).not.toBe(null);

        done();
      });
    });
  });

  describe('loading state', () => {
    it('renders loading state when there is no latest pipeline', done => {
      vm.$store.state.pipelines.latestPipeline = null;
      vm.$store.state.pipelines.isLoadingPipeline = true;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.loading-container')).not.toBe(null);

        done();
      });
    });
  });
});
