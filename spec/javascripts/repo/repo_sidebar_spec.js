import Vue from 'vue';
import RepoStore from '~/repo/repo_store';
import repoSidebar from '~/repo/repo_sidebar.vue';

describe('RepoSidebar', () => {
  function createComponent() {
    const RepoSidebar = Vue.extend(repoSidebar);

    return new RepoSidebar().$mount();
  }

  it('renders a sidebar', () => {
    RepoStore.files = [{
      id: 0,
    }];
    const vm = createComponent();
    const thead = vm.$el.querySelector('thead');
    const tbody = vm.$el.querySelector('tbody');

    expect(vm.$el.id).toEqual('sidebar');
    expect(vm.$el.classList.contains('sidebar-mini')).toBeFalsy();
    expect(thead.querySelector('.name').textContent).toEqual('Name');
    expect(thead.querySelector('.last-commit').textContent).toEqual('Last Commit');
    expect(thead.querySelector('.last-update').textContent).toEqual('Last Update');
    expect(tbody.querySelector('.repo-file-options')).toBeFalsy();
    expect(tbody.querySelector('.prev-directory')).toBeTruthy();
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
});
