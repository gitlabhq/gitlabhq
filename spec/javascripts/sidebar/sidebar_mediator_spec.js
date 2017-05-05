import Vue from 'vue';
import SidebarMediator from '~/sidebar/sidebar_mediator';
import SidebarStore from '~/sidebar/stores/sidebar_store';
import SidebarService from '~/sidebar/services/sidebar_service';
import Mock from './mock_data';

describe('Sidebar mediator', () => {
  beforeEach(() => {
    Vue.http.interceptors.push(Mock.sidebarMockInterceptor);
    this.mediator = new SidebarMediator(Mock.mediator);
  });

  afterEach(() => {
    SidebarService.singleton = null;
    SidebarStore.singleton = null;
    SidebarMediator.singleton = null;
  });

  it('assigns yourself ', () => {
    this.mediator.assignYourself();

    expect(this.mediator.store.currentUser).toEqual(Mock.mediator.currentUser);
    expect(this.mediator.store.assignees[0]).toEqual(Mock.mediator.currentUser);
  });

  it('saves assignees', (done) => {
    this.mediator.saveAssignees('issue[assignee_ids]').then((resp) => {
      expect(resp.status).toEqual(200);
      done();
    });
  });

  it('fetches the data', () => {
    spyOn(this.mediator.service, 'get').and.callThrough();
    this.mediator.fetch();
    expect(this.mediator.service.get).toHaveBeenCalled();
  });
});
