import _ from 'underscore';
import Vue from 'vue';
import * as urlUtils from '~/lib/utils/url_utility';
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
    Vue.http.interceptors = _.without(Vue.http.interceptors, Mock.sidebarMockInterceptor);
  });

  it('assigns yourself ', () => {
    this.mediator.assignYourself();

    expect(this.mediator.store.currentUser).toEqual(Mock.mediator.currentUser);
    expect(this.mediator.store.assignees[0]).toEqual(Mock.mediator.currentUser);
  });

  it('saves assignees', (done) => {
    this.mediator.saveAssignees('issue[assignee_ids]')
      .then((resp) => {
        expect(resp.status).toEqual(200);
        done();
      })
      .catch(done.fail);
  });

  it('fetches the data', (done) => {
    const mockData = Mock.responseMap.GET['/gitlab-org/gitlab-shell/issues/5.json?serializer=sidebar'];
    spyOn(this.mediator, 'processFetchedData').and.callThrough();

    this.mediator.fetch()
      .then(() => {
        expect(this.mediator.processFetchedData).toHaveBeenCalledWith(mockData);
      })
      .then(done)
      .catch(done.fail);
  });

  it('processes fetched data', () => {
    const mockData = Mock.responseMap.GET['/gitlab-org/gitlab-shell/issues/5.json?serializer=sidebar'];
    this.mediator.processFetchedData(mockData);

    expect(this.mediator.store.assignees).toEqual(mockData.assignees);
    expect(this.mediator.store.humanTimeEstimate).toEqual(mockData.human_time_estimate);
    expect(this.mediator.store.humanTotalTimeSpent).toEqual(mockData.human_total_time_spent);
    expect(this.mediator.store.participants).toEqual(mockData.participants);
    expect(this.mediator.store.subscribed).toEqual(mockData.subscribed);
    expect(this.mediator.store.timeEstimate).toEqual(mockData.time_estimate);
    expect(this.mediator.store.totalTimeSpent).toEqual(mockData.total_time_spent);
  });

  it('sets moveToProjectId', () => {
    const projectId = 7;
    spyOn(this.mediator.store, 'setMoveToProjectId').and.callThrough();

    this.mediator.setMoveToProjectId(projectId);

    expect(this.mediator.store.setMoveToProjectId).toHaveBeenCalledWith(projectId);
  });

  it('fetches autocomplete projects', (done) => {
    const searchTerm = 'foo';
    spyOn(this.mediator.service, 'getProjectsAutocomplete').and.callThrough();
    spyOn(this.mediator.store, 'setAutocompleteProjects').and.callThrough();

    this.mediator.fetchAutocompleteProjects(searchTerm)
      .then(() => {
        expect(this.mediator.service.getProjectsAutocomplete).toHaveBeenCalledWith(searchTerm);
        expect(this.mediator.store.setAutocompleteProjects).toHaveBeenCalled();
      })
      .then(done)
      .catch(done.fail);
  });

  it('moves issue', (done) => {
    const moveToProjectId = 7;
    this.mediator.store.setMoveToProjectId(moveToProjectId);
    spyOn(this.mediator.service, 'moveIssue').and.callThrough();
    spyOn(urlUtils, 'visitUrl');

    this.mediator.moveIssue()
      .then(() => {
        expect(this.mediator.service.moveIssue).toHaveBeenCalledWith(moveToProjectId);
        expect(urlUtils.visitUrl).toHaveBeenCalledWith('/root/some-project/issues/5');
      })
      .then(done)
      .catch(done.fail);
  });

  it('toggle subscription', (done) => {
    this.mediator.store.setSubscribedState(false);
    spyOn(this.mediator.service, 'toggleSubscription').and.callThrough();

    this.mediator.toggleSubscription()
      .then(() => {
        expect(this.mediator.service.toggleSubscription).toHaveBeenCalled();
        expect(this.mediator.store.subscribed).toEqual(true);
      })
      .then(done)
      .catch(done.fail);
  });
});
