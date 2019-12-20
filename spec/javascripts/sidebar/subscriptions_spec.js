import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockTracking } from 'spec/helpers/tracking_helper';
import subscriptions from '~/sidebar/components/subscriptions/subscriptions.vue';
import eventHub from '~/sidebar/event_hub';

describe('Subscriptions', function() {
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

    expect(vm.$refs.toggleButton.isLoading).toBe(true);
    expect(vm.$refs.toggleButton.$el.querySelector('.project-feature-toggle')).toHaveClass(
      'is-loading',
    );
  });

  it('is toggled "off" when currently not subscribed', () => {
    vm = mountComponent(Subscriptions, {
      subscribed: false,
    });

    expect(vm.$refs.toggleButton.$el.querySelector('.project-feature-toggle')).not.toHaveClass(
      'is-checked',
    );
  });

  it('is toggled "on" when currently subscribed', () => {
    vm = mountComponent(Subscriptions, {
      subscribed: true,
    });

    expect(vm.$refs.toggleButton.$el.querySelector('.project-feature-toggle')).toHaveClass(
      'is-checked',
    );
  });

  it('toggleSubscription method emits `toggleSubscription` event on eventHub and Component', () => {
    vm = mountComponent(Subscriptions, { subscribed: true });
    spyOn(eventHub, '$emit');
    spyOn(vm, '$emit');
    spyOn(vm, 'track');

    vm.toggleSubscription();

    expect(eventHub.$emit).toHaveBeenCalledWith('toggleSubscription', jasmine.any(Object));
    expect(vm.$emit).toHaveBeenCalledWith('toggleSubscription', jasmine.any(Object));
  });

  it('tracks the event when toggled', () => {
    vm = mountComponent(Subscriptions, { subscribed: true });
    const spy = mockTracking('_category_', vm.$el, spyOn);
    vm.toggleSubscription();

    expect(spy).toHaveBeenCalled();
  });

  it('onClickCollapsedIcon method emits `toggleSidebar` event on component', () => {
    vm = mountComponent(Subscriptions, { subscribed: true });
    spyOn(vm, '$emit');

    vm.onClickCollapsedIcon();

    expect(vm.$emit).toHaveBeenCalledWith('toggleSidebar');
  });

  describe('given project emails are disabled', () => {
    const subscribeDisabledDescription = 'Notifications have been disabled';

    beforeEach(() => {
      vm = mountComponent(Subscriptions, {
        subscribed: false,
        projectEmailsDisabled: true,
        subscribeDisabledDescription,
      });
    });

    it('sets the correct display text', () => {
      expect(vm.$el.textContent).toContain(subscribeDisabledDescription);
      expect(vm.$refs.tooltip.dataset.originalTitle).toBe(subscribeDisabledDescription);
    });

    it('does not render the toggle button', () => {
      expect(vm.$refs.toggleButton).toBeUndefined();
    });
  });
});
