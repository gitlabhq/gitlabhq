import _ from 'underscore';
import Vue from 'vue';
import eventHub from '~/deploy_keys/eventhub';
import deployKeysApp from '~/deploy_keys/components/app.vue';

describe('Deploy keys app component', () => {
  const data = getJSONFixture('deploy_keys/keys.json');
  let vm;

  const deployKeysResponse = (request, next) => {
    next(request.respondWith(JSON.stringify(data), {
      status: 200,
    }));
  };

  beforeEach((done) => {
    const Component = Vue.extend(deployKeysApp);

    Vue.http.interceptors.push(deployKeysResponse);

    vm = new Component({
      propsData: {
        endpoint: '/test',
      },
    }).$mount();

    setTimeout(done);
  });

  afterEach(() => {
    Vue.http.interceptors = _.without(Vue.http.interceptors, deployKeysResponse);
  });

  it('renders loading icon', (done) => {
    vm.store.keys = {};
    vm.isLoading = false;

    Vue.nextTick(() => {
      expect(
        vm.$el.querySelectorAll('.deploy-keys-panel').length,
      ).toBe(0);

      expect(
        vm.$el.querySelector('.fa-spinner'),
      ).toBeDefined();

      done();
    });
  });

  it('renders keys panels', () => {
    expect(
      vm.$el.querySelectorAll('.deploy-keys-panel').length,
    ).toBe(3);
  });

  it('does not render key panels when keys object is empty', (done) => {
    vm.store.keys = {};

    Vue.nextTick(() => {
      expect(
        vm.$el.querySelectorAll('.deploy-keys-panel').length,
      ).toBe(0);

      done();
    });
  });

  it('does not render public panel when empty', (done) => {
    vm.store.keys.public_keys = [];

    Vue.nextTick(() => {
      expect(
        vm.$el.querySelectorAll('.deploy-keys-panel').length,
      ).toBe(2);

      done();
    });
  });

  it('re-fetches deploy keys when enabling a key', (done) => {
    const key = data.public_keys[0];

    spyOn(vm.service, 'getKeys');
    spyOn(vm.service, 'enableKey').and.callFake(() => new Promise((resolve) => {
      resolve();

      setTimeout(() => {
        expect(vm.service.getKeys).toHaveBeenCalled();

        done();
      });
    }));

    eventHub.$emit('enable.key', key);

    expect(vm.service.enableKey).toHaveBeenCalledWith(key.id);
  });

  it('re-fetches deploy keys when disabling a key', (done) => {
    const key = data.public_keys[0];

    spyOn(window, 'confirm').and.returnValue(true);
    spyOn(vm.service, 'getKeys');
    spyOn(vm.service, 'disableKey').and.callFake(() => new Promise((resolve) => {
      resolve();

      setTimeout(() => {
        expect(vm.service.getKeys).toHaveBeenCalled();

        done();
      });
    }));

    eventHub.$emit('disable.key', key);

    expect(vm.service.disableKey).toHaveBeenCalledWith(key.id);
  });

  it('calls disableKey when removing a key', (done) => {
    const key = data.public_keys[0];

    spyOn(window, 'confirm').and.returnValue(true);
    spyOn(vm.service, 'getKeys');
    spyOn(vm.service, 'disableKey').and.callFake(() => new Promise((resolve) => {
      resolve();

      setTimeout(() => {
        expect(vm.service.getKeys).toHaveBeenCalled();

        done();
      });
    }));

    eventHub.$emit('remove.key', key);

    expect(vm.service.disableKey).toHaveBeenCalledWith(key.id);
  });

  it('hasKeys returns true when there are keys', () => {
    expect(vm.hasKeys).toEqual(3);
  });

  it('resets remove button loading state', (done) => {
    spyOn(window, 'confirm').and.returnValue(false);

    const btn = vm.$el.querySelector('.btn-warning');

    btn.click();

    Vue.nextTick(() => {
      expect(btn.querySelector('.fa')).toBeNull();

      done();
    });
  });
});
