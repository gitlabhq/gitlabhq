import Vue from 'vue';
import DeployKeysStore from '~/deploy_keys/store';
import key from '~/deploy_keys/components/key.vue';
import { getTimeago } from '~/lib/utils/datetime_utility';

describe('Deploy keys key', () => {
  let vm;
  const KeyComponent = Vue.extend(key);
  const data = getJSONFixture('deploy_keys/keys.json');
  const createComponent = deployKey => {
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

    beforeEach(done => {
      createComponent(deployKey);

      setTimeout(done);
    });

    it('renders the keys title', () => {
      expect(vm.$el.querySelector('.title').textContent.trim()).toContain('My title');
    });

    it('renders human friendly formatted created date', () => {
      expect(vm.$el.querySelector('.key-created-at').textContent.trim()).toBe(
        `${getTimeago().format(deployKey.created_at)}`,
      );
    });

    it('shows pencil button for editing', () => {
      expect(vm.$el.querySelector('.btn .ic-pencil')).toExist();
    });

    it('shows disable button when the project is not deletable', () => {
      expect(vm.$el.querySelector('.btn .ic-cancel')).toExist();
    });

    it('shows remove button when the project is deletable', done => {
      vm.deployKey.destroyed_when_orphaned = true;
      vm.deployKey.almost_orphaned = true;
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.btn .ic-remove')).toExist();
        done();
      });
    });
  });

  describe('deploy key labels', () => {
    it('shows write access title when key has write access', done => {
      vm.deployKey.deploy_keys_projects[0].can_push = true;

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelector('.deploy-project-label').getAttribute('data-original-title'),
        ).toBe('Write access allowed');
        done();
      });
    });

    it('does not show write access title when key has write access', done => {
      vm.deployKey.deploy_keys_projects[0].can_push = false;

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelector('.deploy-project-label').getAttribute('data-original-title'),
        ).toBe('Read access only');
        done();
      });
    });

    it('shows expandable button if more than two projects', () => {
      const labels = vm.$el.querySelectorAll('.deploy-project-label');
      expect(labels.length).toBe(2);
      expect(labels[1].textContent).toContain('others');
      expect(labels[1].getAttribute('data-original-title')).toContain('Expand');
    });

    it('expands all project labels after click', done => {
      const length = vm.deployKey.deploy_keys_projects.length;
      vm.$el.querySelectorAll('.deploy-project-label')[1].click();

      Vue.nextTick(() => {
        const labels = vm.$el.querySelectorAll('.deploy-project-label');
        expect(labels.length).toBe(length);
        expect(labels[1].textContent).not.toContain(`+${length} others`);
        expect(labels[1].getAttribute('data-original-title')).not.toContain('Expand');
        done();
      });
    });

    it('shows two projects', done => {
      vm.deployKey.deploy_keys_projects = [...vm.deployKey.deploy_keys_projects].slice(0, 2);

      Vue.nextTick(() => {
        const labels = vm.$el.querySelectorAll('.deploy-project-label');
        expect(labels.length).toBe(2);
        expect(labels[1].textContent).toContain(
          vm.deployKey.deploy_keys_projects[1].project.full_name,
        );
        done();
      });
    });
  });

  describe('public keys', () => {
    const deployKey = data.public_keys[0];

    beforeEach(done => {
      createComponent(deployKey);

      setTimeout(done);
    });

    it('renders deploy keys without any enabled projects', done => {
      vm.deployKey.deploy_keys_projects = [];

      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.deploy-project-list').textContent.trim()).toBe('None');

        done();
      });
    });

    it('shows enable button', () => {
      expect(vm.$el.querySelectorAll('.btn')[0].textContent.trim()).toBe('Enable');
    });

    it('shows pencil button for editing', () => {
      expect(vm.$el.querySelector('.btn .ic-pencil')).toExist();
    });

    it('shows disable button when key is enabled', done => {
      vm.store.keys.enabled_keys.push(deployKey);

      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.btn .ic-cancel')).toExist();

        done();
      });
    });
  });
});
