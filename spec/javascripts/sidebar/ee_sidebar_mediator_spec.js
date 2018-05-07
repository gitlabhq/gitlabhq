import Vue from 'vue';
import _ from 'underscore';
import SidebarMediator from 'ee/sidebar/sidebar_mediator';
import CESidebarMediator from '~/sidebar/sidebar_mediator';
import CESidebarStore from '~/sidebar/stores/sidebar_store';
import SidebarService from '~/sidebar/services/sidebar_service';
import Mock from './ee_mock_data';

describe('EE Sidebar mediator', function() {
  beforeEach(() => {
    Vue.http.interceptors.push(Mock.sidebarMockInterceptor);
    this.mediator = new SidebarMediator(Mock.mediator);
  });

  afterEach(() => {
    SidebarService.singleton = null;
    CESidebarStore.singleton = null;
    CESidebarMediator.singleton = null;
    Vue.http.interceptors = _.without(Vue.http.interceptors, Mock.sidebarMockInterceptor);
  });

  it('processes fetched data', () => {
    const mockData =
      Mock.responseMap.GET['/gitlab-org/gitlab-shell/issues/5.json?serializer=sidebar'];
    this.mediator.processFetchedData(mockData);

    expect(this.mediator.store.weight).toEqual(mockData.weight);
  });
});
