import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import SidebarMediator from '~/sidebar/sidebar_mediator';
import SidebarStore from '~/sidebar/stores/sidebar_store';
import SidebarService from '~/sidebar/services/sidebar_service';
import Mock from './mock_data';

describe('Sidebar mediator', function() {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);

    this.mediator = new SidebarMediator(Mock.mediator);
  });

  afterEach(() => {
    SidebarService.singleton = null;
    SidebarStore.singleton = null;
    SidebarMediator.singleton = null;
    mock.restore();
  });

  it('assigns yourself ', () => {
    this.mediator.assignYourself();

    expect(this.mediator.store.currentUser).toEqual(Mock.mediator.currentUser);
    expect(this.mediator.store.assignees[0]).toEqual(Mock.mediator.currentUser);
  });

  it('saves assignees', done => {
    mock.onPut('/gitlab-org/gitlab-shell/issues/5.json?serializer=sidebar_extras').reply(200, {});
    this.mediator
      .saveAssignees('issue[assignee_ids]')
      .then(resp => {
        expect(resp.status).toEqual(200);
        done();
      })
      .catch(done.fail);
  });

  it('fetches the data', done => {
    const mockData =
      Mock.responseMap.GET['/gitlab-org/gitlab-shell/issues/5.json?serializer=sidebar_extras'];
    mock
      .onGet('/gitlab-org/gitlab-shell/issues/5.json?serializer=sidebar_extras')
      .reply(200, mockData);
    spyOn(this.mediator, 'processFetchedData').and.callThrough();

    this.mediator
      .fetch()
      .then(() => {
        expect(this.mediator.processFetchedData).toHaveBeenCalledWith(mockData);
      })
      .then(done)
      .catch(done.fail);
  });

  it('processes fetched data', () => {
    const mockData =
      Mock.responseMap.GET['/gitlab-org/gitlab-shell/issues/5.json?serializer=sidebar_extras'];
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

  it('fetches autocomplete projects', done => {
    const searchTerm = 'foo';
    mock.onGet('/autocomplete/projects?project_id=15').reply(200, {});
    spyOn(this.mediator.service, 'getProjectsAutocomplete').and.callThrough();
    spyOn(this.mediator.store, 'setAutocompleteProjects').and.callThrough();

    this.mediator
      .fetchAutocompleteProjects(searchTerm)
      .then(() => {
        expect(this.mediator.service.getProjectsAutocomplete).toHaveBeenCalledWith(searchTerm);
        expect(this.mediator.store.setAutocompleteProjects).toHaveBeenCalled();
      })
      .then(done)
      .catch(done.fail);
  });

  it('moves issue', done => {
    const mockData = Mock.responseMap.POST['/gitlab-org/gitlab-shell/issues/5/move'];
    const moveToProjectId = 7;
    mock.onPost('/gitlab-org/gitlab-shell/issues/5/move').reply(200, mockData);
    this.mediator.store.setMoveToProjectId(moveToProjectId);
    spyOn(this.mediator.service, 'moveIssue').and.callThrough();
    const visitUrl = spyOnDependency(SidebarMediator, 'visitUrl');

    this.mediator
      .moveIssue()
      .then(() => {
        expect(this.mediator.service.moveIssue).toHaveBeenCalledWith(moveToProjectId);
        expect(visitUrl).toHaveBeenCalledWith('/root/some-project/issues/5');
      })
      .then(done)
      .catch(done.fail);
  });

  it('toggle subscription', done => {
    this.mediator.store.setSubscribedState(false);
    mock.onPost('/gitlab-org/gitlab-shell/issues/5/toggle_subscription').reply(200, {});
    spyOn(this.mediator.service, 'toggleSubscription').and.callThrough();

    this.mediator
      .toggleSubscription()
      .then(() => {
        expect(this.mediator.service.toggleSubscription).toHaveBeenCalled();
        expect(this.mediator.store.subscribed).toEqual(true);
      })
      .then(done)
      .catch(done.fail);
  });
});
