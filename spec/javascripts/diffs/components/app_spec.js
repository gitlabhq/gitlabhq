import Vue from 'vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { TEST_HOST } from 'spec/test_constants';
import App from '~/diffs/components/app.vue';
import createDiffsStore from '../create_diffs_store';

describe('diffs/components/app', () => {
  const oldMrTabs = window.mrTabs;
  const Component = Vue.extend(App);

  let vm;

  beforeEach(() => {
    // setup globals (needed for component to mount :/)
    window.mrTabs = jasmine.createSpyObj('mrTabs', ['resetViewContainer']);
    window.mrTabs.expandViewContainer = jasmine.createSpy();
    window.location.hash = 'ABC_123';

    // setup component
    const store = createDiffsStore();
    store.state.diffs.isLoading = false;

    vm = mountComponentWithStore(Component, {
      store,
      props: {
        endpoint: `${TEST_HOST}/diff/endpoint`,
        projectPath: 'namespace/project',
        currentUser: {},
      },
    });
  });

  afterEach(() => {
    // reset globals
    window.mrTabs = oldMrTabs;

    // reset component
    vm.$destroy();
  });

  it('does not show commit info', () => {
    expect(vm.$el).not.toContainElement('.blob-commit-info');
  });

  it('sets highlighted row if hash exists in location object', done => {
    vm.$props.shouldShow = true;

    vm.$nextTick()
      .then(() => {
        expect(vm.$store.state.diffs.highlightedRow).toBe('ABC_123');
      })
      .then(done)
      .catch(done.fail);
  });
});
