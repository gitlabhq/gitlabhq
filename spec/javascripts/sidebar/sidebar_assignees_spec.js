import Vue from 'vue';
import SidebarAssignees from '~/sidebar/components/assignees/sidebar_assignees';
import SidebarMediator from '~/sidebar/sidebar_mediator';
import SidebarService from '~/sidebar/services/sidebar_service';
import SidebarStore from '~/sidebar/stores/sidebar_store';
import Mock from './mock_data';

describe('sidebar assignees', () => {
  let component;
  let SidebarAssigneeComponent;
  preloadFixtures('issues/open-issue.html.raw');

  beforeEach(() => {
    Vue.http.interceptors.push(Mock.sidebarMockInterceptor);
    SidebarAssigneeComponent = Vue.extend(SidebarAssignees);
    spyOn(SidebarMediator.prototype, 'saveAssignees').and.callThrough();
    spyOn(SidebarMediator.prototype, 'assignYourself').and.callThrough();
    this.mediator = new SidebarMediator(Mock.mediator);
    loadFixtures('issues/open-issue.html.raw');
    this.sidebarAssigneesEl = document.querySelector('#js-vue-sidebar-assignees');
  });

  afterEach(() => {
    SidebarService.singleton = null;
    SidebarStore.singleton = null;
    SidebarMediator.singleton = null;
  });

  it('calls the mediator when saves the assignees', () => {
    component = new SidebarAssigneeComponent()
      .$mount(this.sidebarAssigneesEl);
    component.saveAssignees();

    expect(SidebarMediator.prototype.saveAssignees).toHaveBeenCalled();
  });

  it('calls the mediator when "assignSelf" method is called', () => {
    component = new SidebarAssigneeComponent()
      .$mount(this.sidebarAssigneesEl);
    component.assignSelf();

    expect(SidebarMediator.prototype.assignYourself).toHaveBeenCalled();
    expect(this.mediator.store.assignees.length).toEqual(1);
  });
});
