import Vue from 'vue';
import repoTabs from '~/repo/repo_tabs.vue';

describe('RepoTabss', () => {
  const RepoTabs = Vue.extend(repoTabs);

  function createComponent() {
    return new RepoTabs().$mount();
  }

  it('renders a list of tabs', () => {
  });

  it('does not render a tabs list if no isMini', () => {
  });
});
