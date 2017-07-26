import Vue from 'vue';
import RepoStore from '~/repo/repo_store';
import repoTabs from '~/repo/repo_tabs.vue';

describe('RepoTabs', () => {
  const openedFiles = [{
    id: 0,
    active: true,
  }, {
    id: 1,
  }];
  function createComponent() {
    const RepoTabs = Vue.extend(repoTabs);

    return new RepoTabs().$mount();
  }

  beforeEach(() => {
    spyOn(repoTabs.methods, 'isOverflow');
  });

  it('renders a list of tabs', () => {
    RepoStore.openedFiles = openedFiles;
    RepoStore.tabsOverflow = true;

    const vm = createComponent();
    const tabs = [...vm.$el.querySelectorAll(':scope > li')];

    expect(vm.$el.id).toEqual('tabs');
    expect(vm.$el.classList.contains('overflown')).toBeTruthy();
    expect(tabs.length).toEqual(2);
    expect(tabs[0].classList.contains('active')).toBeTruthy();
    expect(tabs[1].classList.contains('active')).toBeFalsy();
  });

  it('does not render a tabs list if not isMini', () => {
    RepoStore.openedFiles = [];

    const vm = createComponent();

    expect(vm.$el.innerHTML).toBeFalsy();
  });

  it('does not apply overflown class if not tabsOverflow', () => {
    RepoStore.openedFiles = openedFiles;
    RepoStore.tabsOverflow = false;

    const vm = createComponent();

    expect(vm.$el.classList.contains('overflown')).toBeFalsy();
  });
});
