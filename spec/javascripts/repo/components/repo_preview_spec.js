import Vue from 'vue';
import store from '~/repo/stores';
import repoPreview from '~/repo/components/repo_preview.vue';
import { file, resetStore } from '../helpers';

describe('RepoPreview', () => {
  let vm;
  let f;

  function checkIfLoaded(done) {
    if (vm.previewComponent) {
      done();
    } else {
      setTimeout(checkIfLoaded, 1, done);
    }
  }

  function createComponent(done) {
    const RepoPreview = Vue.extend(repoPreview);

    const comp = new RepoPreview({
      store,
    });

    comp.$store.state.openFiles.push(f);

    vm = comp.$mount();

    checkIfLoaded(done);
  }

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  describe('html', () => {
    beforeEach((done) => {
      f = file();

      Object.assign(f, {
        active: true,
        rich: { html: 'richHTML' },
      });

      createComponent(done);
    });

    it('loads HTML viewer', () => {
      expect(vm.previewComponent.name).toBe('HTMLViewer');
    });
  });

  describe('error', () => {
    beforeEach((done) => {
      f = file();

      Object.assign(f, {
        active: true,
        rich: { html: 'richHTML', renderError: 'error' },
      });

      createComponent(done);
    });

    it('loads HTML viewer', () => {
      expect(vm.previewComponent.name).toBe('ErrorViewer');
    });
  });
});
