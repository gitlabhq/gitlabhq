import Vue from 'vue';
import store from '~/repo/stores';
import repoTabs from '~/repo/components/repo_tabs.vue';
import { file, resetStore } from '../helpers';

describe('RepoTabs', () => {
  const openedFiles = [file(), file()];
  let vm;

  function createComponent() {
    const RepoTabs = Vue.extend(repoTabs);

    return new RepoTabs({
      store,
    }).$mount();
  }

  afterEach(() => {
    resetStore(vm.$store);
  });

  it('renders a list of tabs', (done) => {
    vm = createComponent();
    openedFiles[0].active = true;
    vm.$store.state.openFiles = openedFiles;

    vm.$nextTick(() => {
      const tabs = [...vm.$el.querySelectorAll(':scope > li')];

      expect(tabs.length).toEqual(3);
      expect(tabs[0].classList.contains('active')).toBeTruthy();
      expect(tabs[1].classList.contains('active')).toBeFalsy();
      expect(tabs[2].classList.contains('tabs-divider')).toBeTruthy();

      done();
    });
  });
});
