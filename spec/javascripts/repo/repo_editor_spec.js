import Vue from 'vue';
import repoEditor from '~/repo/repo_editor';

describe('RepoEditor', () => {
  function createComponent() {
    const RepoEditor = Vue.extend(repoEditor);

    return new RepoEditor().$mount();
  }

  it('renders an ide container', () => {
    const vm = createComponent();

    expect(vm.$el.id).toEqual('ide');
  });
});
