import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'spec/test_constants';
import axios from '~/lib/utils/axios_utils';
import eventHub from '~/deploy_keys/eventhub';
import deployKeysApp from '~/deploy_keys/components/app.vue';

describe('Deploy keys app component', () => {
  const data = getJSONFixture('deploy_keys/keys.json');
  let vm;
  let mock;

  beforeEach(done => {
    // set up axios mock before component
    mock = new MockAdapter(axios);
    mock.onGet(`${TEST_HOST}/dummy/`).replyOnce(200, data);

    const Component = Vue.extend(deployKeysApp);

    vm = new Component({
      propsData: {
        endpoint: `${TEST_HOST}/dummy`,
        projectId: '8',
      },
    }).$mount();

    setTimeout(done);
  });

  afterEach(() => {
    mock.restore();
  });

  it('renders loading icon', done => {
    vm.store.keys = {};
    vm.isLoading = false;

    Vue.nextTick(() => {
      expect(vm.$el.querySelectorAll('.deploy-keys .nav-links li').length).toBe(0);

      expect(vm.$el.querySelector('.fa-spinner')).toBeDefined();

      done();
    });
  });

  it('renders keys panels', () => {
    expect(vm.$el.querySelectorAll('.deploy-keys .nav-links li').length).toBe(3);
  });

  it('renders the titles with keys count', () => {
    const textContent = selector => {
      const element = vm.$el.querySelector(`${selector}`);

      expect(element).not.toBeNull();
      return element.textContent.trim();
    };

    expect(textContent('.js-deployKeys-tab-enabled_keys')).toContain('Enabled deploy keys');
    expect(textContent('.js-deployKeys-tab-available_project_keys')).toContain(
      'Privately accessible deploy keys',
    );

    expect(textContent('.js-deployKeys-tab-public_keys')).toContain(
      'Publicly accessible deploy keys',
    );

    expect(textContent('.js-deployKeys-tab-enabled_keys .badge')).toBe(
      `${vm.store.keys.enabled_keys.length}`,
    );

    expect(textContent('.js-deployKeys-tab-available_project_keys .badge')).toBe(
      `${vm.store.keys.available_project_keys.length}`,
    );

    expect(textContent('.js-deployKeys-tab-public_keys .badge')).toBe(
      `${vm.store.keys.public_keys.length}`,
    );
  });

  it('does not render key panels when keys object is empty', done => {
    vm.store.keys = {};

    Vue.nextTick(() => {
      expect(vm.$el.querySelectorAll('.deploy-keys .nav-links li').length).toBe(0);

      done();
    });
  });

  it('re-fetches deploy keys when enabling a key', done => {
    const key = data.public_keys[0];

    spyOn(vm.service, 'getKeys');
    spyOn(vm.service, 'enableKey').and.callFake(() => Promise.resolve());

    eventHub.$emit('enable.key', key);

    Vue.nextTick(() => {
      expect(vm.service.enableKey).toHaveBeenCalledWith(key.id);
      expect(vm.service.getKeys).toHaveBeenCalled();
      done();
    });
  });

  it('re-fetches deploy keys when disabling a key', done => {
    const key = data.public_keys[0];

    spyOn(window, 'confirm').and.returnValue(true);
    spyOn(vm.service, 'getKeys');
    spyOn(vm.service, 'disableKey').and.callFake(() => Promise.resolve());

    eventHub.$emit('disable.key', key);

    Vue.nextTick(() => {
      expect(vm.service.disableKey).toHaveBeenCalledWith(key.id);
      expect(vm.service.getKeys).toHaveBeenCalled();
      done();
    });
  });

  it('calls disableKey when removing a key', done => {
    const key = data.public_keys[0];

    spyOn(window, 'confirm').and.returnValue(true);
    spyOn(vm.service, 'getKeys');
    spyOn(vm.service, 'disableKey').and.callFake(() => Promise.resolve());

    eventHub.$emit('remove.key', key);

    Vue.nextTick(() => {
      expect(vm.service.disableKey).toHaveBeenCalledWith(key.id);
      expect(vm.service.getKeys).toHaveBeenCalled();
      done();
    });
  });

  it('hasKeys returns true when there are keys', () => {
    expect(vm.hasKeys).toEqual(3);
  });

  it('resets disable button loading state', done => {
    spyOn(window, 'confirm').and.returnValue(false);

    const btn = vm.$el.querySelector('.btn-warning');

    btn.click();

    Vue.nextTick(() => {
      expect(btn.querySelector('.btn-warning')).not.toExist();

      done();
    });
  });
});
