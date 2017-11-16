import Vue from 'vue';
import store from '~/repo/stores';
import repoSidebar from '~/repo/components/repo_sidebar.vue';
import { file, resetStore } from '../helpers';

describe('RepoSidebar', () => {
  let vm;

  beforeEach(() => {
    const RepoSidebar = Vue.extend(repoSidebar);

    vm = new RepoSidebar({
      store,
    });

    vm.$store.state.isRoot = true;
    vm.$store.state.tree.push(file());

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders a sidebar', () => {
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

  it('does not render a thead, renders repo-file-options and sets sidebar-mini class if isMini', (done) => {
    vm.$store.state.openFiles.push(vm.$store.state.tree[0]);

    Vue.nextTick(() => {
      expect(vm.$el.classList.contains('sidebar-mini')).toBeTruthy();
      expect(vm.$el.querySelector('thead')).toBeTruthy();
      expect(vm.$el.querySelector('thead .repo-file-options')).toBeTruthy();

      done();
    });
  });

  it('renders 5 loading files if tree is loading', (done) => {
    vm.$store.state.tree = [];
    vm.$store.state.loading = true;

    Vue.nextTick(() => {
      expect(vm.$el.querySelectorAll('tbody .loading-file').length).toEqual(5);

      done();
    });
  });

  it('renders a prev directory if is not root', (done) => {
    vm.$store.state.isRoot = false;

    Vue.nextTick(() => {
      expect(vm.$el.querySelector('tbody .prev-directory')).toBeTruthy();

      done();
    });
  });
});
