import Vue from 'vue';
import sidebarSubscriptions from '~/sidebar/components/subscriptions/sidebar_subscriptions.vue';
import SidebarMediator from '~/sidebar/sidebar_mediator';
import SidebarService from '~/sidebar/services/sidebar_service';
import SidebarStore from '~/sidebar/stores/sidebar_store';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import Mock from './mock_data';

describe('Sidebar Subscriptions', function () {
  let vm;
  let SidebarSubscriptions;

  beforeEach(() => {
    SidebarSubscriptions = Vue.extend(sidebarSubscriptions);
    // Setup the stores, services, etc
    // eslint-disable-next-line no-new
    new SidebarMediator(Mock.mediator);
  });

  afterEach(() => {
    vm.$destroy();
    SidebarService.singleton = null;
    SidebarStore.singleton = null;
    SidebarMediator.singleton = null;
  });

  it('calls the mediator toggleSubscription on event', () => {
    const mediator = new SidebarMediator();
    spyOn(mediator, 'toggleSubscription').and.returnValue(Promise.resolve());
    vm = mountComponent(SidebarSubscriptions, {
      mediator,
    });

    vm.onToggleSubscription();

    expect(mediator.toggleSubscription).toHaveBeenCalled();
  });
});
