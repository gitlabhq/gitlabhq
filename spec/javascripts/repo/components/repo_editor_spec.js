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
    vm.$store.getters.activeFile.html = 'testing';
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
      expect(vm.$el.textContent.trim()).toBe('');

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
      expect(vm.$el.textContent.trim()).toBe('testing');
    });
  });

  describe('when open file is locked', () => {
    beforeEach((done) => {
      const f = file('test', '123', 'plaintext');
      f.active = true;
      f.tempFile = true;

      const RepoEditor = Vue.extend(repoEditor);

      vm = new RepoEditor({
        store,
      });

      // Stubbing the getRawFileData Method to return a plain content
      spyOn(vm, 'getRawFileData').and.callFake(() => Promise.resolve('testing'));

      // Spying on setupEditor so we know when the async process executed
      vm.oldSetupEditor = vm.setupEditor;
      spyOn(vm, 'setupEditor').and.callFake(() => {
        spyOn(vm.monacoInstance, 'updateOptions');
        vm.oldSetupEditor();
        Vue.nextTick(() => {
          done();
        });
      });

      vm.$store.state.openFiles.push(f);
      vm.$store.getters.activeFile.html = 'testing';
      vm.$store.getters.activeFile.file_lock = {
        user: {
          name: 'testuser',
          updated_at: new Date(),
        },
      };

      vm.$mount();
    });

    it('Monaco should be in read-only mode', () => {
      expect(vm.monacoInstance.updateOptions).toHaveBeenCalledWith({
        readOnly: true,
      });
    });
  });
});
