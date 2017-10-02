import Vue from 'vue';
import Helper from '~/repo/helpers/repo_helper';
import RepoService from '~/repo/services/repo_service';
import RepoStore from '~/repo/stores/repo_store';
import repoSidebar from '~/repo/components/repo_sidebar.vue';

describe('RepoSidebar', () => {
  function createComponent() {
    const RepoSidebar = Vue.extend(repoSidebar);

    return new RepoSidebar().$mount();
  }

  it('renders a sidebar', () => {
    RepoStore.files = [{
      id: 0,
    }];
    RepoStore.openedFiles = [];
    const vm = createComponent();
    const thead = vm.$el.querySelector('thead');
    const tbody = vm.$el.querySelector('tbody');

    expect(vm.$el.id).toEqual('sidebar');
    expect(vm.$el.classList.contains('sidebar-mini')).toBeFalsy();
    expect(thead.querySelector('.name').textContent).toEqual('Name');
    expect(thead.querySelector('.last-commit').textContent).toEqual('Last Commit');
    expect(thead.querySelector('.last-update').textContent).toEqual('Last Update');
    expect(tbody.querySelector('.repo-file-options')).toBeFalsy();
    expect(tbody.querySelector('.prev-directory')).toBeFalsy();
    expect(tbody.querySelector('.loading-file')).toBeFalsy();
    expect(tbody.querySelector('.file')).toBeTruthy();
  });

  it('does not render a thead, renders repo-file-options and sets sidebar-mini class if isMini', () => {
    RepoStore.openedFiles = [{
      id: 0,
    }];
    const vm = createComponent();

    expect(vm.$el.classList.contains('sidebar-mini')).toBeTruthy();
    expect(vm.$el.querySelector('thead')).toBeFalsy();
    expect(vm.$el.querySelector('tbody .repo-file-options')).toBeTruthy();
  });

  it('renders 5 loading files if tree is loading and not hasFiles', () => {
    RepoStore.loading = {
      tree: true,
    };
    RepoStore.files = [];
    const vm = createComponent();

    expect(vm.$el.querySelectorAll('tbody .loading-file').length).toEqual(5);
  });

  it('renders a prev directory if isRoot', () => {
    RepoStore.files = [{
      id: 0,
    }];
    RepoStore.isRoot = true;
    const vm = createComponent();

    expect(vm.$el.querySelector('tbody .prev-directory')).toBeTruthy();
  });

  describe('methods', () => {
    describe('fileClicked', () => {
      it('should fetch data for new file', () => {
        spyOn(Helper, 'getContent').and.callThrough();
        const file1 = {
          id: 0,
          url: '',
        };
        RepoStore.files = [file1];
        RepoStore.isRoot = true;
        const vm = createComponent();

        vm.fileClicked(file1);

        expect(Helper.getContent).toHaveBeenCalledWith(file1);
      });

      it('should not fetch data for already opened files', () => {
        const file = {
          id: 42,
          url: 'foo',
        };

        spyOn(Helper, 'getFileFromPath').and.returnValue(file);
        spyOn(RepoStore, 'setActiveFiles');
        const vm = createComponent();
        vm.fileClicked(file);

        expect(RepoStore.setActiveFiles).toHaveBeenCalledWith(file);
      });

      it('should hide files in directory if already open', () => {
        spyOn(RepoStore, 'removeChildFilesOfTree').and.callThrough();
        const file1 = {
          id: 0,
          type: 'tree',
          url: '',
          opened: true,
        };
        RepoStore.files = [file1];
        RepoStore.isRoot = true;
        const vm = createComponent();

        vm.fileClicked(file1);

        expect(RepoStore.removeChildFilesOfTree).toHaveBeenCalledWith(file1);
      });
    });

    describe('goToPreviousDirectoryClicked', () => {
      it('should hide files in directory if already open', () => {
        const prevUrl = 'foo/bar';
        const vm = createComponent();

        vm.goToPreviousDirectoryClicked(prevUrl);

        expect(RepoService.url).toEqual(prevUrl);
      });
    });

    describe('back button', () => {
      const file1 = {
        id: 1,
        url: 'file1',
      };
      const file2 = {
        id: 2,
        url: 'file2',
      };
      RepoStore.files = [file1, file2];
      RepoStore.openedFiles = [file1, file2];
      RepoStore.isRoot = true;

      const vm = createComponent();
      vm.fileClicked(file1);

      it('render previous file when using back button', () => {
        spyOn(Helper, 'getContent').and.callThrough();
        vm.fileClicked(file2);
        expect(Helper.getContent).toHaveBeenCalledWith(file2);

        history.pushState({
          key: Math.random(),
        }, '', file1.url);
        const popEvent = document.createEvent('Event');
        popEvent.initEvent('popstate', true, true);
        window.dispatchEvent(popEvent);

        expect(Helper.getContent).toHaveBeenCalledWith(file1);
      });
    });
  });
});
