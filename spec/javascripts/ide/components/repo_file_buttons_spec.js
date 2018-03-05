import Vue from 'vue';
import store from 'ee/ide/stores';
import repoFileButtons from 'ee/ide/components/repo_file_buttons.vue';
import { file, resetStore } from '../helpers';

describe('RepoFileButtons', () => {
  const activeFile = file();
  let vm;

  function createComponent() {
    const RepoFileButtons = Vue.extend(repoFileButtons);

    activeFile.rawPath = 'test';
    activeFile.blamePath = 'test';
    activeFile.commitsPath = 'test';
    activeFile.active = true;
    store.state.openFiles.push(activeFile);

    return new RepoFileButtons({
      store,
    }).$mount();
  }

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders Raw, Blame, History, Permalink and Preview toggle', (done) => {
    vm = createComponent();

    vm.$nextTick(() => {
      const raw = vm.$el.querySelector('.raw');
      const blame = vm.$el.querySelector('.blame');
      const history = vm.$el.querySelector('.history');

      expect(raw.href).toMatch(`/${activeFile.rawPath}`);
      expect(raw.textContent.trim()).toEqual('Raw');
      expect(blame.href).toMatch(`/${activeFile.blamePath}`);
      expect(blame.textContent.trim()).toEqual('Blame');
      expect(history.href).toMatch(`/${activeFile.commitsPath}`);
      expect(history.textContent.trim()).toEqual('History');
      expect(vm.$el.querySelector('.permalink').textContent.trim()).toEqual('Permalink');

      done();
    });
  });
});
