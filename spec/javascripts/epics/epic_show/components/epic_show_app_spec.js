import Vue from 'vue';
import epicShowApp from 'ee/epics/epic_show/components/epic_show_app.vue';
import epicHeader from 'ee/epics/epic_show/components/epic_header.vue';
import epicSidebar from 'ee/epics/sidebar/components/sidebar_app.vue';
import issuableApp from '~/issue_show/components/app.vue';
import mountComponent from '../../../helpers/vue_mount_component_helper';
import { props } from '../mock_data';
import issueShowData from '../../../issue_show/mock_data';

describe('EpicShowApp', () => {
  let vm;
  let headerVm;
  let issuableAppVm;
  let sidebarVm;

  const interceptor = (request, next) => {
    if (request.url === '/realtime_changes') {
      next(request.respondWith(JSON.stringify(issueShowData.initialRequest), {
        status: 200,
      }));
    } else {
      next(request.respondWith(null, {
        status: 404,
      }));
    }
  };

  beforeEach(() => {
    Vue.http.interceptors.push(interceptor);

    const {
      canUpdate,
      canDestroy,
      endpoint,
      initialTitleHtml,
      initialTitleText,
      startDate,
      endDate,
      markdownPreviewPath,
      markdownDocsPath,
      author,
      created,
    } = props;

    const EpicShowApp = Vue.extend(epicShowApp);
    vm = mountComponent(EpicShowApp, props);

    const EpicHeader = Vue.extend(epicHeader);
    headerVm = mountComponent(EpicHeader, {
      author,
      created,
    });

    const IssuableApp = Vue.extend(issuableApp);
    issuableAppVm = mountComponent(IssuableApp, {
      canUpdate,
      canDestroy,
      endpoint,
      issuableRef: '',
      initialTitleHtml,
      initialTitleText,
      initialDescriptionHtml: '',
      initialDescriptionText: '',
      markdownPreviewPath,
      markdownDocsPath,
      projectPath: props.groupPath,
      projectNamespace: '',
      showInlineEditButton: true,
    });

    const EpicSidebar = Vue.extend(epicSidebar);
    sidebarVm = mountComponent(EpicSidebar, {
      endpoint,
      editable: canUpdate,
      initialStartDate: startDate,
      initialEndDate: endDate,
    });
  });

  afterEach(() => {
    Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
  });

  it('should render epic-header', () => {
    expect(vm.$el.innerHTML.indexOf(headerVm.$el.innerHTML) !== -1).toEqual(true);
  });

  it('should render issuable-app', () => {
    expect(vm.$el.innerHTML.indexOf(issuableAppVm.$el.innerHTML) !== -1).toEqual(true);
  });

  it('should render epic-sidebar', () => {
    expect(vm.$el.innerHTML.indexOf(sidebarVm.$el.innerHTML) !== -1).toEqual(true);
  });
});
