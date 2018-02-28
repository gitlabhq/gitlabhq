import Vue from 'vue';
import repoPreview from '~/repo/components/repo_preview.vue';
import RepoStore from '~/repo/stores/repo_store';

describe('RepoPreview', () => {
  function createComponent() {
    const RepoPreview = Vue.extend(repoPreview);

    return new RepoPreview().$mount();
  }

  it('renders a div with the activeFile html', () => {
    const activeFile = {
      html: '<p class="file-content">html</p>',
    };
    RepoStore.activeFile = activeFile;

    const vm = createComponent();

    expect(vm.$el.tagName).toEqual('DIV');
    expect(vm.$el.innerHTML).toContain(activeFile.html);
  });
});
