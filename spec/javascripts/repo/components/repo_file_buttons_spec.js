import Vue from 'vue';
import store from '~/repo/stores';
import repoFileButtons from '~/repo/components/repo_file_buttons.vue';
import { file, resetStore } from '../helpers';

describe('RepoFileButtons', () => {
  let activeFile;
  let vm;

  function createComponent() {
    const RepoFileButtons = Vue.extend(repoFileButtons);

    activeFile = file();
    Object.assign(activeFile, {
      rawPath: 'test',
      blamePath: 'test',
      commitsPath: 'test',
      active: true,
      rich: { path: 'test' },
      simple: { name: 'text', path: 'test' },
    });
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
      expect(raw.querySelector('.fa').classList.contains('fa-file-code-o')).toBeTruthy();
      expect(blame.href).toMatch(`/${activeFile.blamePath}`);
      expect(blame.textContent.trim()).toEqual('Blame');
      expect(history.href).toMatch(`/${activeFile.commitsPath}`);
      expect(history.textContent.trim()).toEqual('History');
      expect(vm.$el.querySelector('.permalink').textContent.trim()).toEqual('Permalink');
      expect(vm.$el.querySelector('.fa-clipboard')).not.toBeNull();

      done();
    });
  });

  describe('binary file', () => {
    beforeEach((done) => {
      vm = createComponent();

      activeFile.binary = true;

      Vue.nextTick(done);
    });

    it('renders download icon when binary', () => {
      expect(vm.$el.querySelector('.raw .fa').classList.contains('fa-download')).toBeTruthy();
    });

    it('does not render clipboard button when binary', () => {
      expect(vm.$el.querySelector('.fa-clipboard')).toBeNull();
    });
  });
});
