import Vue from 'vue';
import repoFileButtons from '~/repo/repo_file_buttons.vue';
import RepoStore from '~/repo/repo_store';

describe('RepoFileButtons', () => {
  function createComponent() {
    const RepoFileButtons = Vue.extend(repoFileButtons);

    return new RepoFileButtons().$mount();
  }

  it('renders Raw, Blame, History, Permalink, Lock and Preview toggle', () => {
    const activeFile = {
      extension: 'md',
      url: 'url',
    };
    const activeFileLabel = 'activeFileLabel';
    RepoStore.openedFiles = new Array(1);
    RepoStore.activeFile = activeFile;
    RepoStore.activeFileLabel = activeFileLabel;
    RepoStore.editMode = true;

    const vm = createComponent();
    const raw = vm.$el.querySelector('.raw');
    const blame = vm.$el.querySelector('.blame');
    const history = vm.$el.querySelector('.history');

    expect(vm.$el.id).toEqual('repo-file-buttons');
    expect(vm.$el.style.borderBottom).toEqual('1px solid rgb(31, 120, 209)');
    expect(raw.href).toMatch(`/${activeFile.url}`);
    expect(raw.textContent).toEqual('Raw');
    expect(blame.href).toMatch(`/${activeFile.url}`);
    expect(blame.textContent).toEqual('Blame');
    expect(history.href).toMatch(`/${activeFile.url}`);
    expect(history.textContent).toEqual('History');
    expect(vm.$el.querySelector('.permalink').textContent).toEqual('Permalink');
    expect(vm.$el.querySelector('.lock').textContent).toEqual('Lock');
    expect(vm.$el.querySelector('.preview').textContent).toEqual(activeFileLabel);
  });

  it('renders a white border if not editMode', () => {
    const activeFile = {
      extension: 'md',
      url: 'url',
    };
    RepoStore.openedFiles = new Array(1);
    RepoStore.activeFile = activeFile;
    RepoStore.editMode = false;

    const vm = createComponent();

    expect(vm.$el.style.borderBottom).toEqual('1px solid rgb(240, 240, 240)');
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

  it('does not render if not isMini', () => {
    RepoStore.openedFiles = [];

    const vm = createComponent();

    expect(vm.$el.innerHTML).toBeFalsy();
  });
});
