import Vue from 'vue';
import store from 'ee/ide/stores';
import repoPreview from 'ee/ide/components/repo_preview.vue';
import { file, resetStore } from '../helpers';

describe('RepoPreview', () => {
  let vm;

  function createComponent() {
    const f = file();
    const RepoPreview = Vue.extend(repoPreview);

    const comp = new RepoPreview({
      store,
    });

    f.active = true;
    f.html = 'test';

    comp.$store.state.openFiles.push(f);

    return comp.$mount();
  }

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders a div with the activeFile html', () => {
    vm = createComponent();

    expect(vm.$el.tagName).toEqual('DIV');
    expect(vm.$el.innerHTML).toContain('test');
  });
});
