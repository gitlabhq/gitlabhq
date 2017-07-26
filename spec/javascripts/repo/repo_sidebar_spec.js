import Vue from 'vue';
import RepoStore from '~/repo/repo_store';
import repoSidebar from '~/repo/repo_sidebar.vue';

describe('RepoSidebar', () => {
  function createComponent() {
    const RepoSidebar = Vue.extend(repoSidebar);

    return new RepoSidebar().$mount();
  }

  it('renders a list of tabs', () => {
    const vm = createComponent();
  });
});
