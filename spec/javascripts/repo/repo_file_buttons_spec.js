import Vue from 'vue';
import repoFileButtons from '~/repo/repo_file_buttons.vue';
import RepoStore from '~/repo/repo_store';

describe('RepoFileButtons', () => {
  function createComponent() {
    const RepoFileButtons = Vue.extend(repoFileButtons);

    return new RepoFileButtons().$mount();
  }

  it('renders Raw, Blame, History, Permalink, Lock, Preview toggle, Replace and Delete', () => {
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
    const permalink = vm.$el.querySelector('.permalink');
    const lock = vm.$el.querySelector('.lock');
    const preview = vm.$el.querySelector('.preview');
    const replace = vm.$el.querySelector('.replace');
    const deleteBtn = vm.$el.querySelector('.delete');

    expect(vm.$el.id).toEqual('repo-file-buttons');
    expect(vm.$el.style.borderBottom).toEqual('1px solid rgb(31, 120, 209)');
    expect(raw).toBeTruthy();
    expect(raw.href).toMatch(`/${activeFile.url}`);
    expect(raw.textContent).toEqual('Raw');
    expect(blame).toBeTruthy();
    expect(blame.href).toMatch(`/${activeFile.url}`);
    expect(blame.textContent).toEqual('Blame');
    expect(history).toBeTruthy();
    expect(history.href).toMatch(`/${activeFile.url}`);
    expect(history.textContent).toEqual('History');
    expect(permalink).toBeTruthy();
    expect(permalink.textContent).toEqual('Permalink');
    expect(lock).toBeTruthy();
    expect(lock.textContent).toEqual('Lock');
    expect(preview).toBeTruthy();
    expect(preview.textContent).toEqual(activeFileLabel);
    expect(replace).toBeTruthy();
    expect(replace.dataset.target).toEqual('#modal-upload-blob');
    expect(replace.dataset.toggle).toEqual('modal');
    expect(replace.textContent).toEqual('Replace');
    expect(deleteBtn).toBeTruthy();
    expect(deleteBtn.textContent).toEqual('Delete');
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
