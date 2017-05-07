import Vue from 'vue';
import SidebarBundleDomContentLoaded from '~/sidebar/sidebar_bundle';
import SidebarTimeTracking from '~/sidebar/components/time_tracking/sidebar_time_tracking';
import SidebarMediator from '~/sidebar/sidebar_mediator';
import SidebarService from '~/sidebar/services/sidebar_service';
import SidebarStore from '~/sidebar/stores/sidebar_store';
import Mock from './mock_data';

describe('sidebar bundle', () => {
  gl.sidebarOptions = Mock.mediator;

  beforeEach(() => {
    spyOn(SidebarTimeTracking.methods, 'listenForSlashCommands').and.callFake(() => { });
    preloadFixtures('issues/open-issue.html.raw');
    Vue.http.interceptors.push(Mock.sidebarMockInterceptor);
    loadFixtures('issues/open-issue.html.raw');
    spyOn(Vue.prototype, '$mount');
    SidebarBundleDomContentLoaded();
    this.mediator = new SidebarMediator();
  });

  afterEach(() => {
    SidebarService.singleton = null;
    SidebarStore.singleton = null;
    SidebarMediator.singleton = null;
  });

  it('the mediator should be already defined with some data', () => {
    SidebarBundleDomContentLoaded();

    expect(this.mediator.store).toBeDefined();
    expect(this.mediator.service).toBeDefined();
    expect(this.mediator.store.currentUser).toEqual(Mock.mediator.currentUser);
    expect(this.mediator.store.rootPath).toEqual(Mock.mediator.rootPath);
    expect(this.mediator.store.endPoint).toEqual(Mock.mediator.endPoint);
    expect(this.mediator.store.editable).toEqual(Mock.mediator.editable);
  });

  it('the sidebar time tracking and assignees components to have been mounted', () => {
    expect(Vue.prototype.$mount).toHaveBeenCalledTimes(2);
  });
});
