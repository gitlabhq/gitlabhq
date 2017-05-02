import Vue from 'vue';
import DeployKeysStore from '~/deploy_keys/store';
import deployKeysPanel from '~/deploy_keys/components/keys_panel.vue';

describe('Deploy keys panel', () => {
  const data = getJSONFixture('deploy_keys/keys.json');
  let vm;

  beforeEach((done) => {
    const DeployKeysPanelComponent = Vue.extend(deployKeysPanel);
    const store = new DeployKeysStore();
    store.keys = data;

    vm = new DeployKeysPanelComponent({
      propsData: {
        title: 'test',
        keys: data.enabled_keys,
        showHelpBox: true,
        store,
      },
    }).$mount();

    setTimeout(done);
  });

  it('renders the title with keys count', () => {
    expect(
      vm.$el.querySelector('h5').textContent.trim(),
    ).toContain('test');

    expect(
      vm.$el.querySelector('h5').textContent.trim(),
    ).toContain('(1)');
  });

  it('renders list of keys', () => {
    expect(
      vm.$el.querySelectorAll('li').length,
    ).toBe(1);
  });

  it('renders help box if keys are empty', (done) => {
    vm.keys = [];

    Vue.nextTick(() => {
      expect(
        vm.$el.querySelector('.settings-message'),
      ).toBeDefined();

      expect(
        vm.$el.querySelector('.settings-message').textContent.trim(),
      ).toBe('No deploy keys found. Create one with the form above.');

      done();
    });
  });

  it('does not render help box if keys are empty & showHelpBox is false', (done) => {
    vm.keys = [];
    vm.showHelpBox = false;

    Vue.nextTick(() => {
      expect(
        vm.$el.querySelector('.settings-message'),
      ).toBeNull();

      done();
    });
  });
});
