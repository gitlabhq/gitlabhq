import Vue from 'vue';
import Helper from '~/repo/helpers/repo_helper';
import RepoService from '~/repo/services/repo_service';
import RepoStore from '~/repo/stores/repo_store';
import repoSidebar from '~/repo/components/repo_sidebar.vue';
import { file } from '../mock_data';

describe('RepoSidebar', () => {
  let vm;

  function createComponent() {
    const RepoSidebar = Vue.extend(repoSidebar);

    return new RepoSidebar().$mount();
  }

  afterEach(() => {
    vm.$destroy();

    RepoStore.files = [];
    RepoStore.openedFiles = [];
  });

  it('renders a sidebar', () => {
    RepoStore.files = [file()];
    RepoStore.openedFiles = [];
    RepoStore.isRoot = true;

    vm = createComponent();
    const thead = vm.$el.querySelector('thead');
    const tbody = vm.$el.querySelector('tbody');

    expect(vm.$el.id).toEqual('sidebar');
    expect(vm.$el.classList.contains('sidebar-mini')).toBeFalsy();
    expect(thead.querySelector('.name').textContent.trim()).toEqual('Name');
    expect(thead.querySelector('.last-commit').textContent.trim()).toEqual('Last commit');
    expect(thead.querySelector('.last-update').textContent.trim()).toEqual('Last update');
    expect(tbody.querySelector('.repo-file-options')).toBeFalsy();
    expect(tbody.querySelector('.prev-directory')).toBeFalsy();
    expect(tbody.querySelector('.loading-file')).toBeFalsy();
    expect(tbody.querySelector('.file')).toBeTruthy();
  });

  it('does not render a thead, renders repo-file-options and sets sidebar-mini class if isMini', () => {
    RepoStore.openedFiles = [{
      id: 0,
    }];
    vm = createComponent();

    expect(vm.$el.classList.contains('sidebar-mini')).toBeTruthy();
    expect(vm.$el.querySelector('thead')).toBeTruthy();
    expect(vm.$el.querySelector('thead .repo-file-options')).toBeTruthy();
  });

  it('renders 5 loading files if tree is loading and not hasFiles', () => {
    RepoStore.loading.tree = true;
    RepoStore.files = [];
    vm = createComponent();

    expect(vm.$el.querySelectorAll('tbody .loading-file').length).toEqual(5);
  });

  it('renders a prev directory if is not root', () => {
    RepoStore.files = [file()];
    RepoStore.isRoot = false;
    RepoStore.loading.tree = false;
    vm = createComponent();

    expect(vm.$el.querySelector('tbody .prev-directory')).toBeTruthy();
  });

  describe('flattendFiles', () => {
    it('returns a flattend array of files', () => {
      const f = file();
      f.files.push(file('testing 123'));
      const files = [f, file()];
      vm = createComponent();
      vm.files = files;

      expect(vm.flattendFiles.length).toBe(3);
      expect(vm.flattendFiles[1].name).toBe('testing 123');
    });
  });

  describe('methods', () => {
    describe('fileClicked', () => {
      it('should fetch data for new file', () => {
        spyOn(Helper, 'getContent').and.callThrough();
        RepoStore.files = [file()];
        RepoStore.isRoot = true;
        vm = createComponent();

        vm.fileClicked(RepoStore.files[0]);

        expect(Helper.getContent).toHaveBeenCalledWith(RepoStore.files[0]);
      });

      it('should not fetch data for already opened files', () => {
        const f = file();
        spyOn(Helper, 'getFileFromPath').and.returnValue(f);
        spyOn(RepoStore, 'setActiveFiles');
        vm = createComponent();
        vm.fileClicked(f);

        expect(RepoStore.setActiveFiles).toHaveBeenCalledWith(f);
      });

      it('should hide files in directory if already open', () => {
        spyOn(Helper, 'setDirectoryToClosed').and.callThrough();
        const f = file();
        f.opened = true;
        f.type = 'tree';
        RepoStore.files = [f];
        vm = createComponent();

        vm.fileClicked(RepoStore.files[0]);

        expect(Helper.setDirectoryToClosed).toHaveBeenCalledWith(RepoStore.files[0]);
      });
    });

    describe('goToPreviousDirectoryClicked', () => {
      it('should hide files in directory if already open', () => {
        const prevUrl = 'foo/bar';
        vm = createComponent();

        vm.goToPreviousDirectoryClicked(prevUrl);

        expect(RepoService.url).toEqual(prevUrl);
      });
    });

    describe('back button', () => {
      beforeEach(() => {
        const f = file();
        const file2 = Object.assign({}, file());
        file2.url = 'test';
        RepoStore.files = [f, file2];
        RepoStore.openedFiles = [];
        RepoStore.isRoot = true;

        vm = createComponent();
      });

      it('render previous file when using back button', () => {
        spyOn(Helper, 'getContent').and.callThrough();

        vm.fileClicked(RepoStore.files[1]);
        expect(Helper.getContent).toHaveBeenCalledWith(RepoStore.files[1]);

        history.pushState({
          key: Math.random(),
        }, '', RepoStore.files[1].url);
        const popEvent = document.createEvent('Event');
        popEvent.initEvent('popstate', true, true);
        window.dispatchEvent(popEvent);

        expect(Helper.getContent.calls.mostRecent().args[0].url).toContain(RepoStore.files[1].url);

        window.history.pushState({}, null, '/');
      });
    });
  });
});
