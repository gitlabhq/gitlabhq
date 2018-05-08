import Vue from 'vue';
import DeployKeysStore from '~/deploy_keys/store';
import key from '~/deploy_keys/components/key.vue';
import { getTimeago } from '~/lib/utils/datetime_utility';

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
        endpoint: 'https://test.host/dummy/endpoint',
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
      ).toBe(`created ${getTimeago().format(deployKey.created_at)}`);
    });

    it('shows edit button', () => {
      expect(
        vm.$el.querySelectorAll('.btn')[0].textContent.trim(),
      ).toBe('Edit');
    });

    it('shows remove button', () => {
      expect(
        vm.$el.querySelectorAll('.btn')[1].textContent.trim(),
      ).toBe('Remove');
    });

    it('shows write access title when key has write access', (done) => {
      vm.deployKey.deploy_keys_projects[0].can_push = true;

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelector('.deploy-project-label').getAttribute('data-original-title'),
        ).toBe('Write access allowed');
        done();
      });
    });

    it('does not show write access title when key has write access', (done) => {
      vm.deployKey.deploy_keys_projects[0].can_push = false;

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelector('.deploy-project-label').getAttribute('data-original-title'),
        ).toBe('Read access only');
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

    it('shows edit button', () => {
      expect(
        vm.$el.querySelectorAll('.btn')[0].textContent.trim(),
      ).toBe('Edit');
    });

    it('shows enable button', () => {
      expect(
        vm.$el.querySelectorAll('.btn')[1].textContent.trim(),
      ).toBe('Enable');
    });

    it('shows disable button when key is enabled', (done) => {
      vm.store.keys.enabled_keys.push(deployKey);

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelectorAll('.btn')[1].textContent.trim(),
        ).toBe('Disable');

        done();
      });
    });
  });
});
