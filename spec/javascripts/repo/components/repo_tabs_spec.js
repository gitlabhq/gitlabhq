import Vue from 'vue';
import store from '~/ide/stores';
import repoTabs from '~/ide/components/repo_tabs.vue';
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
      const tabs = [...vm.$el.querySelectorAll('.multi-file-tab')];

      expect(tabs.length).toEqual(2);
      expect(tabs[0].classList.contains('active')).toBeTruthy();
      expect(tabs[1].classList.contains('active')).toBeFalsy();

      done();
    });
  });
});
