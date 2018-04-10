import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import pipelinesComp from '~/pipelines/components/pipelines.vue';
import Store from '~/pipelines/stores/pipelines_store';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('Pipelines', () => {
  const jsonFixtureName = 'pipelines/pipelines.json';

  preloadFixtures(jsonFixtureName);

  let PipelinesComponent;
  let pipelines;
  let vm;
  let mock;

  const paths = {
    endpoint: 'twitter/flight/pipelines.json',
    autoDevopsPath: '/help/topics/autodevops/index.md',
    helpPagePath: '/help/ci/quick_start/README',
    emptyStateSvgPath: '/assets/illustrations/pipelines_empty.svg',
    errorStateSvgPath: '/assets/illustrations/pipelines_failed.svg',
    noPipelinesSvgPath: '/assets/illustrations/pipelines_pending.svg',
    ciLintPath: '/ci/lint',
    resetCachePath: '/twitter/flight/settings/ci_cd/reset_cache',
    newPipelinePath: '/twitter/flight/pipelines/new',
  };

  const noPermissions = {
    endpoint: 'twitter/flight/pipelines.json',
    autoDevopsPath: '/help/topics/autodevops/index.md',
    helpPagePath: '/help/ci/quick_start/README',
    emptyStateSvgPath: '/assets/illustrations/pipelines_empty.svg',
    errorStateSvgPath: '/assets/illustrations/pipelines_failed.svg',
    noPipelinesSvgPath: '/assets/illustrations/pipelines_pending.svg',
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);

    pipelines = getJSONFixture(jsonFixtureName);

    PipelinesComponent = Vue.extend(pipelinesComp);
  });

  afterEach(() => {
    vm.$destroy();
    mock.restore();
  });

  describe('With permission', () => {
    describe('With pipelines in main tab', () => {
      beforeEach((done) => {
        mock.onGet('twitter/flight/pipelines.json').reply(200, pipelines);

        vm = mountComponent(PipelinesComponent, {
          store: new Store(),
          hasGitlabCi: true,
          canCreatePipeline: true,
          ...paths,
        });

        setTimeout(() => {
          done();
        });
      });

      it('renders tabs', () => {
        expect(vm.$el.querySelector('.js-pipelines-tab-all').textContent.trim()).toContain('All');
      });

      it('renders Run Pipeline link', () => {
        expect(vm.$el.querySelector('.js-run-pipeline').getAttribute('href')).toEqual(paths.newPipelinePath);
      });

      it('renders CI Lint link', () => {
        expect(vm.$el.querySelector('.js-ci-lint').getAttribute('href')).toEqual(paths.ciLintPath);
      });

      it('renders Clear Runner Cache button', () => {
        expect(vm.$el.querySelector('.js-clear-cache').textContent.trim()).toEqual('Clear Runner Caches');
      });

      it('renders pipelines table', () => {
        expect(
          vm.$el.querySelectorAll('.gl-responsive-table-row').length,
        ).toEqual(pipelines.pipelines.length + 1);
      });
    });

    describe('Without pipelines on main tab with CI', () => {
      beforeEach((done) => {
        mock.onGet('twitter/flight/pipelines.json').reply(200, {
          pipelines: [],
          count: {
            all: 0,
            pending: 0,
            running: 0,
            finished: 0,
          },
        });
        vm = mountComponent(PipelinesComponent, {
          store: new Store(),
          hasGitlabCi: true,
          canCreatePipeline: true,
          ...paths,
        });

        setTimeout(() => {
          done();
        });
      });

      it('renders tabs', () => {
        expect(vm.$el.querySelector('.js-pipelines-tab-all').textContent.trim()).toContain('All');
      });

      it('renders Run Pipeline link', () => {
        expect(vm.$el.querySelector('.js-run-pipeline').getAttribute('href')).toEqual(paths.newPipelinePath);
      });

      it('renders CI Lint link', () => {
        expect(vm.$el.querySelector('.js-ci-lint').getAttribute('href')).toEqual(paths.ciLintPath);
      });

      it('renders Clear Runner Cache button', () => {
        expect(vm.$el.querySelector('.js-clear-cache').textContent.trim()).toEqual('Clear Runner Caches');
      });

      it('renders tab empty state', () => {
        expect(vm.$el.querySelector('.empty-state h4').textContent.trim()).toEqual('There are currently no pipelines.');
      });
    });

    describe('Without pipelines nor CI', () => {
      beforeEach((done) => {
        mock.onGet('twitter/flight/pipelines.json').reply(200, {
          pipelines: [],
          count: {
            all: 0,
            pending: 0,
            running: 0,
            finished: 0,
          },
        });
        vm = mountComponent(PipelinesComponent, {
          store: new Store(),
          hasGitlabCi: false,
          canCreatePipeline: true,
          ...paths,
        });

        setTimeout(() => {
          done();
        });
      });

      it('renders empty state', () => {
        expect(vm.$el.querySelector('.js-empty-state h4').textContent.trim()).toEqual('Build with confidence');
        expect(vm.$el.querySelector('.js-get-started-pipelines').getAttribute('href')).toEqual(paths.helpPagePath);
      });

      it('does not render tabs nor buttons', () => {
        expect(vm.$el.querySelector('.js-pipelines-tab-all')).toBeNull();
        expect(vm.$el.querySelector('.js-run-pipeline')).toBeNull();
        expect(vm.$el.querySelector('.js-ci-lint')).toBeNull();
        expect(vm.$el.querySelector('.js-clear-cache')).toBeNull();
      });
    });

    describe('When API returns error', () => {
      beforeEach((done) => {
        mock.onGet('twitter/flight/pipelines.json').reply(500, {});
        vm = mountComponent(PipelinesComponent, {
          store: new Store(),
          hasGitlabCi: false,
          canCreatePipeline: true,
          ...paths,
        });

        setTimeout(() => {
          done();
        });
      });

      it('renders tabs', () => {
        expect(vm.$el.querySelector('.js-pipelines-tab-all').textContent.trim()).toContain('All');
      });

      it('renders buttons', () => {
        expect(vm.$el.querySelector('.js-run-pipeline').getAttribute('href')).toEqual(paths.newPipelinePath);
        expect(vm.$el.querySelector('.js-ci-lint').getAttribute('href')).toEqual(paths.ciLintPath);
        expect(vm.$el.querySelector('.js-clear-cache').textContent.trim()).toEqual('Clear Runner Caches');
      });

      it('renders error state', () => {
        expect(vm.$el.querySelector('.empty-state').textContent.trim()).toContain('There was an error fetching the pipelines.');
      });
    });
  });

  describe('Without permission', () => {
    describe('With pipelines in main tab', () => {
      beforeEach((done) => {
        mock.onGet('twitter/flight/pipelines.json').reply(200, pipelines);

        vm = mountComponent(PipelinesComponent, {
          store: new Store(),
          hasGitlabCi: false,
          canCreatePipeline: false,
          ...noPermissions,
        });

        setTimeout(() => {
          done();
        });
      });

      it('renders tabs', () => {
        expect(vm.$el.querySelector('.js-pipelines-tab-all').textContent.trim()).toContain('All');
      });

      it('does not render buttons', () => {
        expect(vm.$el.querySelector('.js-run-pipeline')).toBeNull();
        expect(vm.$el.querySelector('.js-ci-lint')).toBeNull();
        expect(vm.$el.querySelector('.js-clear-cache')).toBeNull();
      });

      it('renders pipelines table', () => {
        expect(
          vm.$el.querySelectorAll('.gl-responsive-table-row').length,
        ).toEqual(pipelines.pipelines.length + 1);
      });
    });

    describe('Without pipelines on main tab with CI', () => {
      beforeEach((done) => {
        mock.onGet('twitter/flight/pipelines.json').reply(200, {
          pipelines: [],
          count: {
            all: 0,
            pending: 0,
            running: 0,
            finished: 0,
          },
        });

        vm = mountComponent(PipelinesComponent, {
          store: new Store(),
          hasGitlabCi: true,
          canCreatePipeline: false,
          ...noPermissions,
        });

        setTimeout(() => {
          done();
        });
      });

      it('renders tabs', () => {
        expect(vm.$el.querySelector('.js-pipelines-tab-all').textContent.trim()).toContain('All');
      });

      it('does not render buttons', () => {
        expect(vm.$el.querySelector('.js-run-pipeline')).toBeNull();
        expect(vm.$el.querySelector('.js-ci-lint')).toBeNull();
        expect(vm.$el.querySelector('.js-clear-cache')).toBeNull();
      });

      it('renders tab empty state', () => {
        expect(vm.$el.querySelector('.empty-state h4').textContent.trim()).toEqual('There are currently no pipelines.');
      });
    });

    describe('Without pipelines nor CI', () => {
      beforeEach((done) => {
        mock.onGet('twitter/flight/pipelines.json').reply(200, {
          pipelines: [],
          count: {
            all: 0,
            pending: 0,
            running: 0,
            finished: 0,
          },
        });

        vm = mountComponent(PipelinesComponent, {
          store: new Store(),
          hasGitlabCi: false,
          canCreatePipeline: false,
          ...noPermissions,
        });

        setTimeout(() => {
          done();
        });
      });

      it('renders empty state without button to set CI', () => {
        expect(vm.$el.querySelector('.js-empty-state').textContent.trim()).toEqual('This project is not currently set up to run pipelines.');
        expect(vm.$el.querySelector('.js-get-started-pipelines')).toBeNull();
      });

      it('does not render tabs or buttons', () => {
        expect(vm.$el.querySelector('.js-pipelines-tab-all')).toBeNull();
        expect(vm.$el.querySelector('.js-run-pipeline')).toBeNull();
        expect(vm.$el.querySelector('.js-ci-lint')).toBeNull();
        expect(vm.$el.querySelector('.js-clear-cache')).toBeNull();
      });
    });

    describe('When API returns error', () => {
      beforeEach((done) => {
        mock.onGet('twitter/flight/pipelines.json').reply(500, {});

        vm = mountComponent(PipelinesComponent, {
          store: new Store(),
          hasGitlabCi: false,
          canCreatePipeline: true,
          ...noPermissions,
        });

        setTimeout(() => {
          done();
        });
      });

      it('renders tabs', () => {
        expect(vm.$el.querySelector('.js-pipelines-tab-all').textContent.trim()).toContain('All');
      });

      it('does not renders buttons', () => {
        expect(vm.$el.querySelector('.js-run-pipeline')).toBeNull();
        expect(vm.$el.querySelector('.js-ci-lint')).toBeNull();
        expect(vm.$el.querySelector('.js-clear-cache')).toBeNull();
      });

      it('renders error state', () => {
        expect(vm.$el.querySelector('.empty-state').textContent.trim()).toContain('There was an error fetching the pipelines.');
      });
    });
  });

  describe('successfull request', () => {
    describe('with pipelines', () => {
      beforeEach(() => {
        mock.onGet('twitter/flight/pipelines.json').reply(200, pipelines);

        vm = mountComponent(PipelinesComponent, {
          store: new Store(),
          hasGitlabCi: true,
          canCreatePipeline: true,
          ...paths,
        });
      });

      it('should render table', (done) => {
        setTimeout(() => {
          expect(vm.$el.querySelector('.table-holder')).toBeDefined();
          expect(
            vm.$el.querySelectorAll('.gl-responsive-table-row').length,
          ).toEqual(pipelines.pipelines.length + 1);
          done();
        });
      });

      it('should render navigation tabs', (done) => {
        setTimeout(() => {
          expect(
            vm.$el.querySelector('.js-pipelines-tab-pending').textContent.trim(),
          ).toContain('Pending');
          expect(
            vm.$el.querySelector('.js-pipelines-tab-all').textContent.trim(),
          ).toContain('All');
          expect(
            vm.$el.querySelector('.js-pipelines-tab-running').textContent.trim(),
          ).toContain('Running');
          expect(
            vm.$el.querySelector('.js-pipelines-tab-finished').textContent.trim(),
          ).toContain('Finished');
          expect(
            vm.$el.querySelector('.js-pipelines-tab-branches').textContent.trim(),
          ).toContain('Branches');
          expect(
            vm.$el.querySelector('.js-pipelines-tab-tags').textContent.trim(),
          ).toContain('Tags');
          done();
        });
      });

      it('should make an API request when using tabs', (done) => {
        setTimeout(() => {
          spyOn(vm, 'updateContent');
          vm.$el.querySelector('.js-pipelines-tab-finished').click();

          expect(vm.updateContent).toHaveBeenCalledWith({ scope: 'finished', page: '1' });
          done();
        });
      });

      describe('with pagination', () => {
        it('should make an API request when using pagination', (done) => {
          setTimeout(() => {
            spyOn(vm, 'updateContent');
            // Mock pagination
            vm.store.state.pageInfo = {
              page: 1,
              total: 10,
              perPage: 2,
              nextPage: 2,
              totalPages: 5,
            };

            vm.$nextTick(() => {
              vm.$el.querySelector('.js-next-button a').click();
              expect(vm.updateContent).toHaveBeenCalledWith({ scope: 'all', page: '2' });

              done();
            });
          });
        });
      });
    });
  });

  describe('methods', () => {
    beforeEach(() => {
      spyOn(history, 'pushState').and.stub();
    });

    describe('updateContent', () => {
      it('should set given parameters', () => {
        vm = mountComponent(PipelinesComponent, {
          store: new Store(),
          hasGitlabCi: true,
          canCreatePipeline: true,
          ...paths,
        });
        vm.updateContent({ scope: 'finished', page: '4' });

        expect(vm.page).toEqual('4');
        expect(vm.scope).toEqual('finished');
        expect(vm.requestData.scope).toEqual('finished');
        expect(vm.requestData.page).toEqual('4');
      });
    });

    describe('onChangeTab', () => {
      it('should set page to 1', () => {
        vm = mountComponent(PipelinesComponent, {
          store: new Store(),
          hasGitlabCi: true,
          canCreatePipeline: true,
          ...paths,
        });
        spyOn(vm, 'updateContent');

        vm.onChangeTab('running');

        expect(vm.updateContent).toHaveBeenCalledWith({ scope: 'running', page: '1' });
      });
    });

    describe('onChangePage', () => {
      it('should update page and keep scope', () => {
        vm = mountComponent(PipelinesComponent, {
          store: new Store(),
          hasGitlabCi: true,
          canCreatePipeline: true,
          ...paths,
        });
        spyOn(vm, 'updateContent');

        vm.onChangePage(4);

        expect(vm.updateContent).toHaveBeenCalledWith({ scope: vm.scope, page: '4' });
      });
    });
  });

  describe('computed properties', () => {
    beforeEach(() => {
      vm = mountComponent(PipelinesComponent, {
        store: new Store(),
        hasGitlabCi: true,
        canCreatePipeline: true,
        ...paths,
      });
    });

    describe('tabs', () => {
      it('returns default tabs', () => {
        expect(vm.tabs).toEqual([
          { name: 'All', scope: 'all', count: undefined, isActive: true },
          { name: 'Pending', scope: 'pending', count: undefined, isActive: false },
          { name: 'Running', scope: 'running', count: undefined, isActive: false },
          { name: 'Finished', scope: 'finished', count: undefined, isActive: false },
          { name: 'Branches', scope: 'branches', isActive: false },
          { name: 'Tags', scope: 'tags', isActive: false },
        ]);
      });
    });

    describe('emptyTabMessage', () => {
      it('returns message with scope', (done) => {
        vm.scope = 'pending';

        vm.$nextTick(() => {
          expect(vm.emptyTabMessage).toEqual('There are currently no pending pipelines.');
          done();
        });
      });

      it('returns message without scope when scope is `all`', () => {
        expect(vm.emptyTabMessage).toEqual('There are currently no pipelines.');
      });
    });

    describe('stateToRender', () => {
      it('returns loading state when the app is loading', () => {
        expect(vm.stateToRender).toEqual('loading');
      });

      it('returns error state when app has error', (done) => {
        vm.hasError = true;
        vm.isLoading = false;

        vm.$nextTick(() => {
          expect(vm.stateToRender).toEqual('error');
          done();
        });
      });

      it('returns table list when app has pipelines', (done) => {
        vm.isLoading = false;
        vm.hasError = false;
        vm.state.pipelines = pipelines.pipelines;

        vm.$nextTick(() => {
          expect(vm.stateToRender).toEqual('tableList');

          done();
        });
      });

      it('returns empty tab when app does not have pipelines but project has pipelines', (done) => {
        vm.state.count.all = 10;
        vm.isLoading = false;

        vm.$nextTick(() => {
          expect(vm.stateToRender).toEqual('emptyTab');

          done();
        });
      });

      it('returns empty tab when project has CI', (done) => {
        vm.isLoading = false;
        vm.$nextTick(() => {
          expect(vm.stateToRender).toEqual('emptyTab');

          done();
        });
      });

      it('returns empty state when project does not have pipelines nor CI', (done) => {
        vm.isLoading = false;
        vm.hasGitlabCi = false;
        vm.$nextTick(() => {
          expect(vm.stateToRender).toEqual('emptyState');

          done();
        });
      });
    });

    describe('shouldRenderTabs', () => {
      it('returns true when state is loading & has already made the first request', (done) => {
        vm.isLoading = true;
        vm.hasMadeRequest = true;

        vm.$nextTick(() => {
          expect(vm.shouldRenderTabs).toEqual(true);

          done();
        });
      });

      it('returns true when state is tableList & has already made the first request', (done) => {
        vm.isLoading = false;
        vm.state.pipelines = pipelines.pipelines;
        vm.hasMadeRequest = true;

        vm.$nextTick(() => {
          expect(vm.shouldRenderTabs).toEqual(true);

          done();
        });
      });

      it('returns true when state is error & has already made the first request', (done) => {
        vm.isLoading = false;
        vm.hasError = true;
        vm.hasMadeRequest = true;

        vm.$nextTick(() => {
          expect(vm.shouldRenderTabs).toEqual(true);

          done();
        });
      });

      it('returns true when state is empty tab & has already made the first request', (done) => {
        vm.isLoading = false;
        vm.state.count.all = 10;
        vm.hasMadeRequest = true;

        vm.$nextTick(() => {
          expect(vm.shouldRenderTabs).toEqual(true);

          done();
        });
      });

      it('returns false when has not made first request', (done) => {
        vm.hasMadeRequest = false;

        vm.$nextTick(() => {
          expect(vm.shouldRenderTabs).toEqual(false);

          done();
        });
      });

      it('returns false when state is emtpy state', (done) => {
        vm.isLoading = false;
        vm.hasMadeRequest = true;
        vm.hasGitlabCi = false;

        vm.$nextTick(() => {
          expect(vm.shouldRenderTabs).toEqual(false);

          done();
        });
      });
    });

    describe('shouldRenderButtons', () => {
      it('returns true when it has paths & has made the first request', (done) => {
        vm.hasMadeRequest = true;

        vm.$nextTick(() => {
          expect(vm.shouldRenderButtons).toEqual(true);

          done();
        });
      });

      it('returns false when it has not made the first request', (done) => {
        vm.hasMadeRequest = false;

        vm.$nextTick(() => {
          expect(vm.shouldRenderButtons).toEqual(false);

          done();
        });
      });
    });
  });
});
