import Vue from 'vue';
import store from '~/repo/stores';
import repoPreview from '~/repo/components/repo_preview.vue';
import { file, resetStore } from '../helpers';

describe('RepoPreview', () => {
  let vm;

  function createComponent(currentViewer = 'rich') {
    const f = file();
    const RepoPreview = Vue.extend(repoPreview);

    const comp = new RepoPreview({
      store,
    });

    Object.assign(f, {
      active: true,
      currentViewer,
      rich: { html: 'richHTML' },
      simple: { html: 'simpleHTML' },
    });

    comp.$store.state.openFiles.push(f);

    return comp.$mount();
  }

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  describe('rich', () => {
    beforeEach((done) => {
      vm = createComponent();

      Vue.nextTick(done);
    });

    it('renders activeFile rich html', () => {
      expect(vm.$el.textContent.trim()).toContain('richHTML');
    });
  });

  describe('simple', () => {
    beforeEach((done) => {
      vm = createComponent('simple');

      Vue.nextTick(done);
    });

    it('renders activeFile rich html', () => {
      expect(vm.$el.textContent.trim()).toContain('simpleHTML');
    });
  });
});
