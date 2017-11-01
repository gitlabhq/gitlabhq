import Vue from 'vue';
import store from '~/repo/stores';
import repoEditor from '~/repo/components/repo_editor.vue';
import { file, resetStore } from '../helpers';

describe('RepoEditor', () => {
  let vm;

  beforeEach(() => {
    const f = file();
    const RepoEditor = Vue.extend(repoEditor);

    vm = new RepoEditor({
      store,
    });

    f.active = true;
    f.tempFile = true;
    vm.$store.state.openFiles.push(f);
    vm.monaco = true;

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders an ide container', (done) => {
    Vue.nextTick(() => {
      expect(vm.shouldHideEditor).toBeFalsy();
      done();
    });
  });

  describe('when open file is binary and not raw', () => {
    it('does not render the IDE', (done) => {
      vm.$store.getters.activeFile.binary = true;

      Vue.nextTick(() => {
        expect(vm.shouldHideEditor).toBeTruthy();
        done();
      });
    });
  });
});
