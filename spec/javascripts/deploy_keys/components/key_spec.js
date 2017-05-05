import Vue from 'vue';
import DeployKeysStore from '~/deploy_keys/store';
import key from '~/deploy_keys/components/key.vue';

describe('Deploy keys key', () => {
  let vm;
  const KeyComponent = Vue.extend(key);
  const data = getJSONFixture('deploy_keys/keys.json');
  const createComponent = (deployKey) => {
    const store = new DeployKeysStore();
    store.keys = data;

    vm = new KeyComponent({
      propsData: {
        deployKey,
        store,
      },
    }).$mount();
  };

  describe('enabled key', () => {
    const deployKey = data.enabled_keys[0];

    beforeEach((done) => {
      createComponent(deployKey);

      setTimeout(done);
    });

    it('renders the keys title', () => {
      expect(
        vm.$el.querySelector('.title').textContent.trim(),
      ).toContain('My title');
    });

    it('renders human friendly formatted created date', () => {
      expect(
        vm.$el.querySelector('.key-created-at').textContent.trim(),
      ).toBe(`created ${gl.utils.getTimeago().format(deployKey.created_at)}`);
    });

    it('shows remove button', () => {
      expect(
        vm.$el.querySelector('.btn').textContent.trim(),
      ).toBe('Remove');
    });

    it('shows write access text when key has write access', (done) => {
      vm.deployKey.can_push = true;

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelector('.write-access-allowed'),
        ).not.toBeNull();

        expect(
          vm.$el.querySelector('.write-access-allowed').textContent.trim(),
        ).toBe('Write access allowed');

        done();
      });
    });
  });

  describe('public keys', () => {
    const deployKey = data.public_keys[0];

    beforeEach((done) => {
      createComponent(deployKey);

      setTimeout(done);
    });

    it('shows enable button', () => {
      expect(
        vm.$el.querySelector('.btn').textContent.trim(),
      ).toBe('Enable');
    });

    it('shows disable button when key is enabled', (done) => {
      vm.store.keys.enabled_keys.push(deployKey);

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelector('.btn').textContent.trim(),
        ).toBe('Disable');

        done();
      });
    });
  });
});
