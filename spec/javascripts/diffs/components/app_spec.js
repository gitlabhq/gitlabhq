import Vue from 'vue';
import App from '~/diffs/components/app.vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { TEST_HOST } from 'spec/test_constants';
import createMockStore from '../create_mock_store';

const TEST_ENDPOINT = `${TEST_HOST}/diff/endpoint`;
const TEST_PROJECT_PATH = 'namespace/project';

describe('diffs App', () => {
  const Component = Vue.extend(App);
  const oldMrTabs = window.mrTabs;

  let vm;

  beforeEach(() => {
    // --- setup globals ---
    window.mrTabs = jasmine.createSpyObj('mrTabs', ['resetViewContainer']);

    // --- setup component ---
    const store = createMockStore();
    store.state.diffs.isLoading = false;

    vm = mountComponentWithStore(Component, {
      store,
      props: {
        endpoint: TEST_ENDPOINT,
        projectPath: TEST_PROJECT_PATH,
        currentUser: {},
      },
    });
  });

  afterEach(() => {
    // --- reset globals ---
    window.mrTabs = oldMrTabs;

    // --- reset component ---
    vm.$destroy();
  });

  it('shows comments message, with commit', done => {
    vm.$store.state.diffs.commit = {};

    vm.$nextTick()
      .then(() => {
        expect(vm.$el).toContainText('Only comments from the following commit are shown below');
      })
      .then(done)
      .catch(done.fail);
  });

  it('shows comments message, with old mergeRequestDiff', done => {
    vm.$store.state.diffs.mergeRequestDiff = {
      latest: false,
    };

    vm.$nextTick()
      .then(() => {
        expect(vm.$el).toContainText("Not all comments are displayed because you're viewing an old version of the diff.");
      })
      .then(done)
      .catch(done.fail);
  });

  it('shows comments message, with startVersion', done => {
    vm.$store.state.diffs.startVersion = 'test';

    vm.$nextTick()
      .then(() => {
        expect(vm.$el).toContainText("Not all comments are displayed because you're comparing two versions of the diff.");
      })
      .then(done)
      .catch(done.fail);
  });
});
