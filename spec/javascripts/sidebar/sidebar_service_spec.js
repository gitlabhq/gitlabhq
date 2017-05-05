import Vue from 'vue';
import SidebarService from '~/sidebar/services/sidebar_service';
import Mock from './mock_data';

describe('Sidebar service', () => {
  beforeEach(() => {
    Vue.http.interceptors.push(Mock.sidebarMockInterceptor);
    this.service = new SidebarService('/gitlab-org/gitlab-shell/issues/5.json');
  });

  afterEach(() => {
    SidebarService.singleton = null;
  });

  it('gets the data', (done) => {
    this.service.get().then((resp) => {
      expect(resp).toBeDefined();
      done();
    });
  });

  it('updates the data', (done) => {
    this.service.update('issue[assignee_ids]', [1]).then((resp) => {
      expect(resp).toBeDefined();
      done();
    });
  });
});
