import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import SidebarAssignees from '~/sidebar/components/assignees/sidebar_assignees.vue';
import SidebarMediator from '~/sidebar/sidebar_mediator';
import SidebarService from '~/sidebar/services/sidebar_service';
import SidebarStore from '~/sidebar/stores/sidebar_store';
import Mock from './mock_data';

describe('sidebar assignees', () => {
  let vm;
  let mediator;
  let sidebarAssigneesEl;
  preloadFixtures('issues/open-issue.html');

  beforeEach(() => {
    loadFixtures('issues/open-issue.html');

    mediator = new SidebarMediator(Mock.mediator);
    spyOn(mediator, 'saveAssignees').and.callThrough();
    spyOn(mediator, 'assignYourself').and.callThrough();

    const SidebarAssigneeComponent = Vue.extend(SidebarAssignees);
    sidebarAssigneesEl = document.querySelector('#js-vue-sidebar-assignees');
    vm = mountComponent(
      SidebarAssigneeComponent,
      {
        mediator,
        field: sidebarAssigneesEl.dataset.field,
      },
      sidebarAssigneesEl,
    );
  });

  afterEach(() => {
    SidebarService.singleton = null;
    SidebarStore.singleton = null;
    SidebarMediator.singleton = null;
  });

  it('calls the mediator when saves the assignees', () => {
    vm.saveAssignees();

    expect(mediator.saveAssignees).toHaveBeenCalled();
  });

  it('calls the mediator when "assignSelf" method is called', () => {
    vm.assignSelf();

    expect(mediator.assignYourself).toHaveBeenCalled();
    expect(mediator.store.assignees.length).toEqual(1);
  });

  it('hides assignees until fetched', done => {
    const currentAssignee = sidebarAssigneesEl.querySelector('.value');

    expect(currentAssignee).toBe(null);

    vm.store.isFetching.assignees = false;
    Vue.nextTick(() => {
      expect(vm.$el.querySelector('.value')).toBeVisible();
      done();
    });
  });
});
