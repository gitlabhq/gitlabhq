import Vue from 'vue';
import subscriptions from '~/sidebar/components/subscriptions/subscriptions.vue';
import mountComponent from '../helpers/vue_mount_component_helper';

describe('Subscriptions', function () {
  let vm;
  let Subscriptions;

  beforeEach(() => {
    Subscriptions = Vue.extend(subscriptions);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('shows loading spinner when loading', () => {
    vm = mountComponent(Subscriptions, {
      loading: true,
      subscribed: undefined,
    });

    expect(vm.$refs.loadingButton.loading).toBe(true);
    expect(vm.$refs.loadingButton.label).toBeUndefined();
  });

  it('has "Subscribe" text when currently not subscribed', () => {
    vm = mountComponent(Subscriptions, {
      subscribed: false,
    });

    expect(vm.$refs.loadingButton.label).toBe('Subscribe');
  });

  it('has "Unsubscribe" text when currently not subscribed', () => {
    vm = mountComponent(Subscriptions, {
      subscribed: true,
    });

    expect(vm.$refs.loadingButton.label).toBe('Unsubscribe');
  });
});
