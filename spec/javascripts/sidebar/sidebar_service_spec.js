import Vue from 'vue';
import SidebarService from '~/sidebar/services/sidebar_service';
import Mock from './mock_data';

describe('Sidebar service', () => {
  beforeEach(() => {
    Vue.http.interceptors.push(Mock.sidebarMockInterceptor);
    this.service = new SidebarService({
      endpoint: '/gitlab-org/gitlab-shell/issues/5.json',
      moveIssueEndpoint: '/gitlab-org/gitlab-shell/issues/5/move',
      projectsAutocompleteEndpoint: '/autocomplete/projects?project_id=15',
    });
  });

  afterEach(() => {
    SidebarService.singleton = null;
    Vue.http.interceptors = _.without(Vue.http.interceptors, Mock.sidebarMockInterceptor);
  });

  it('gets the data', (done) => {
    this.service.get()
      .then((resp) => {
        expect(resp).toBeDefined();
        done();
      })
      .catch(done.fail);
  });

  it('updates the data', (done) => {
    this.service.update('issue[assignee_ids]', [1])
      .then((resp) => {
        expect(resp).toBeDefined();
        done();
      })
      .catch(done.fail);
  });

  it('gets projects for autocomplete', (done) => {
    this.service.getProjectsAutocomplete()
      .then((resp) => {
        expect(resp).toBeDefined();
        done();
      })
      .catch(done.fail);
  });

  it('moves the issue to another project', (done) => {
    this.service.moveIssue(123)
      .then((resp) => {
        expect(resp).toBeDefined();
        done();
      })
      .catch(done.fail);
  });
});
