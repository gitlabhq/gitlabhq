import Vue from 'vue';
import DeployKeysStore from '~/deploy_keys/store';
import deployKeysPanel from '~/deploy_keys/components/keys_panel.vue';

describe('Deploy keys panel', () => {
  const data = getJSONFixture('deploy_keys/keys.json');
  let vm;

  beforeEach(done => {
    const DeployKeysPanelComponent = Vue.extend(deployKeysPanel);
    const store = new DeployKeysStore();
    store.keys = data;

    vm = new DeployKeysPanelComponent({
      propsData: {
        title: 'test',
        keys: data.enabled_keys,
        showHelpBox: true,
        store,
        endpoint: 'https://test.host/dummy/endpoint',
      },
    }).$mount();

    setTimeout(done);
  });

  it('renders list of keys', () => {
    expect(vm.$el.querySelectorAll('.deploy-key').length).toBe(vm.keys.length);
  });

  it('renders table header', () => {
    const tableHeader = vm.$el.querySelector('.table-row-header');

    expect(tableHeader).toExist();
    expect(tableHeader.textContent).toContain('Deploy key');
    expect(tableHeader.textContent).toContain('Project usage');
    expect(tableHeader.textContent).toContain('Created');
  });

  it('renders help box if keys are empty', done => {
    vm.keys = [];

    Vue.nextTick(() => {
      expect(vm.$el.querySelector('.settings-message')).toBeDefined();

      expect(vm.$el.querySelector('.settings-message').textContent.trim()).toBe(
        'No deploy keys found. Create one with the form above.',
      );

      done();
    });
  });

  it('renders no table header if keys are empty', done => {
    vm.keys = [];

    Vue.nextTick(() => {
      expect(vm.$el.querySelector('.table-row-header')).not.toExist();

      done();
    });
  });
});
