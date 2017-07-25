import Vue from 'vue';
import repoEditor from '~/repo/repo_editor.vue';

describe('RepoEditor', () => {
  const RepoEditor = Vue.extend(repoEditor);

  function createComponent() {
    return new RepoEditor().$mount();
  }

  it('renders an ide container', () => {
    const vm = createComponent();

    expect(vm.$el.id).toEqual('ide');
  });
});
