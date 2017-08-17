import Vue from 'vue';
import repoFileButtons from '~/repo/components/repo_file_buttons.vue';
import RepoStore from '~/repo/stores/repo_store';

describe('RepoFileButtons', () => {
  function createComponent() {
    const RepoFileButtons = Vue.extend(repoFileButtons);

    return new RepoFileButtons().$mount();
  }

  it('renders Raw, Blame, History, Permalink and Preview toggle', () => {
    const activeFile = {
      extension: 'md',
      url: 'url',
      raw_path: 'raw_path',
      blame_path: 'blame_path',
      commits_path: 'commits_path',
      permalink: 'permalink',
    };
    const activeFileLabel = 'activeFileLabel';
    RepoStore.openedFiles = new Array(1);
    RepoStore.activeFile = activeFile;
    RepoStore.activeFileLabel = activeFileLabel;
    RepoStore.editMode = true;
    RepoStore.binary = false;

    const vm = createComponent();
    const raw = vm.$el.querySelector('.raw');
    const blame = vm.$el.querySelector('.blame');
    const history = vm.$el.querySelector('.history');

    expect(vm.$el.id).toEqual('repo-file-buttons');
    expect(raw.href).toMatch(`/${activeFile.raw_path}`);
    expect(raw.textContent.trim()).toEqual('Raw');
    expect(blame.href).toMatch(`/${activeFile.blame_path}`);
    expect(blame.textContent.trim()).toEqual('Blame');
    expect(history.href).toMatch(`/${activeFile.commits_path}`);
    expect(history.textContent.trim()).toEqual('History');
    expect(vm.$el.querySelector('.permalink').textContent.trim()).toEqual('Permalink');
    expect(vm.$el.querySelector('.preview').textContent.trim()).toEqual(activeFileLabel);
  });

  it('triggers rawPreviewToggle on preview click', () => {
    const activeFile = {
      extension: 'md',
      url: 'url',
    };
    RepoStore.openedFiles = new Array(1);
    RepoStore.activeFile = activeFile;
    RepoStore.editMode = true;

    const vm = createComponent();
    const preview = vm.$el.querySelector('.preview');

    spyOn(vm, 'rawPreviewToggle');

    preview.click();

    expect(vm.rawPreviewToggle).toHaveBeenCalled();
  });

  it('does not render preview toggle if not canPreview', () => {
    const activeFile = {
      extension: 'abcd',
      url: 'url',
    };
    RepoStore.openedFiles = new Array(1);
    RepoStore.activeFile = activeFile;

    const vm = createComponent();

    expect(vm.$el.querySelector('.preview')).toBeFalsy();
  });
});
