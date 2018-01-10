import Vue from 'vue';
import store from '~/ide/stores';
import repoEditor from '~/ide/components/repo_editor.vue';
import monacoLoader from '~/ide/monaco_loader';
import { file, resetStore } from '../helpers';

describe('RepoEditor', () => {
  let vm;

  beforeEach((done) => {
    const f = file();
    const RepoEditor = Vue.extend(repoEditor);

    vm = new RepoEditor({
      store,
    });

    f.active = true;
    f.tempFile = true;
    vm.$store.state.openFiles.push(f);
    vm.$store.getters.activeFile.html = 'testing';
    vm.monaco = true;

    vm.$mount();

    monacoLoader(['vs/editor/editor.main'], () => {
      setTimeout(done, 0);
    });
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
    beforeEach((done) => {
      vm.$store.getters.activeFile.binary = true;

      Vue.nextTick(done);
    });

    it('does not render the IDE', () => {
      expect(vm.shouldHideEditor).toBeTruthy();
    });

    it('shows activeFile html', () => {
      expect(vm.$el.textContent).toContain('testing');
    });
  });

  describe('computed', () => {
    describe('activeFileChanged', () => {
      it('returns false when file has no changes', () => {
        expect(vm.activeFileChanged).toBeFalsy();
      });

      it('returns true when file has changes', () => {
        vm.$store.getters.activeFile.changed = true;

        expect(vm.activeFileChanged).toBeTruthy();
      });
    });
  });
});
