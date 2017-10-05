import Vue from 'vue';
import repoFileButtons from '~/repo/components/repo_file_buttons.vue';
import RepoStore from '~/repo/stores/repo_store';
import RepoService from '~/repo/services/repo_service';

describe('RepoFileButtons', () => {
  function createComponent() {
    const RepoFileButtons = Vue.extend(repoFileButtons);

    return new RepoFileButtons().$mount();
  }

  const returnPromise = html => new Promise((resolve) => {
    resolve({
      data: { html },
    });
  });

  it('renders Raw, Blame, History, Permalink, Copy source buttons', () => {
    const activeFile = {
      extension: 'md',
      url: 'url',
      raw_path: 'raw_path',
      blame_path: 'blame_path',
      commits_path: 'commits_path',
      permalink: 'permalink',
      previewMode: '',
      viewerHTML: {},
      rich_viewer: null,
      simple_viewer: null,
    };
    const activeFileLabel = 'activeFileLabel';
    RepoStore.openedFiles = new Array(1);
    RepoStore.activeFile = activeFile;
    RepoStore.activeFileLabel = activeFileLabel;
    RepoStore.binary = false;

    const vm = createComponent();
    const raw = vm.$el.querySelector('.raw');
    const blame = vm.$el.querySelector('.blame');
    const history = vm.$el.querySelector('.history');

    expect(vm.$el.id).toEqual('repo-file-buttons');
    expect(raw.href).toMatch(`/${activeFile.raw_path}`);
    expect(blame.href).toMatch(`/${activeFile.blame_path}`);
    expect(blame.textContent.trim()).toEqual('Blame');
    expect(history.href).toMatch(`/${activeFile.commits_path}`);
    expect(history.textContent.trim()).toEqual('History');
    expect(vm.$el.querySelector('.permalink').textContent.trim()).toEqual('Permalink');
    expect(vm.$el.querySelector('.js-btn-copy-clipboard')).toBeTruthy();
    expect(vm.$el.querySelector('.js-viewer-buttons')).toEqual(null);
  });

  it('renders Display Source and Display Rendered buttons', (done) => {
    const vm = createComponent();

    RepoStore.activeFile.previewMode = 'rich';
    RepoStore.activeFile.rich_viewer = {
      switcher_title: 'rich viewer',
      switcher_icon: 'rich-icon',
    };
    RepoStore.activeFile.simple_viewer = {
      switcher_title: 'simple viewer',
      switcher_icon: 'simple-icon',
    };

    vm.$nextTick(() => {
      expect(vm.$el.querySelector('.js-viewer-buttons')).toBeDefined();
      const simpleViewerBtn = vm.$el.querySelector('.js-btn-simple-view');
      const richViewerBtn = vm.$el.querySelector('.js-btn-rich-view');

      expect(simpleViewerBtn.querySelector('i').classList.contains('fa-simple-icon')).toBeTruthy();
      expect(simpleViewerBtn.getAttribute('data-original-title')).toEqual('Display simple viewer');

      expect(richViewerBtn.querySelector('i').classList.contains('fa-rich-icon')).toBeTruthy();
      expect(richViewerBtn.classList.contains('active')).toBeTruthy();

      expect(richViewerBtn.getAttribute('data-original-title')).toEqual('Display rich viewer');
      done();
    });
  });

  describe('toggleViewer', () => {
    const type = 'simple';
    const path = '/foo';
    const html = 'simple viewer html';

    it('should make a request if there is no cached html before', (done) => {
      const vm = createComponent();
      spyOn(RepoService, 'getContent').and.returnValue(returnPromise(html));

      vm.toggleViewer(type, path);

      vm.$nextTick(() => {
        expect(RepoService.getContent).toHaveBeenCalledWith(path);
        expect(RepoStore.activeFile.html).toEqual(html);
        expect(RepoStore.activeFile.previewMode).toEqual(type);
        expect(RepoStore.activeFile.viewerHTML.simple).toEqual(html);
        done();
      });
    });

    it('should not make a request and use cached html', (done) => {
      const vm = createComponent();
      spyOn(RepoService, 'getContent').and.returnValue(returnPromise('rich viewer html'));

      vm.toggleViewer('rich', '/foo');
      vm.$nextTick(() => {
        expect(RepoStore.activeFile.viewerHTML.rich).toEqual('rich viewer html');
        expect(RepoService.getContent.calls.count()).toBe(1);
        vm.toggleViewer(type, path);

        vm.$nextTick(() => {
          expect(RepoService.getContent.calls.count()).toBe(1);
          expect(RepoStore.activeFile.html).toEqual(html);
          done();
        });
      });
    });
  });
});
