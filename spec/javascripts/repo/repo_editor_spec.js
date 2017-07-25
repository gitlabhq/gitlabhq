import Vue from 'vue';
import repoEditor from '~/repo/repo_editor.vue';

fdescribe('RepoEditor', () => {
  const RepoEditor = Vue.extend(repoEditor);

  function createComponent() {
    return new RepoEditor().$mount();
  }

  it('renders an ide container', () => {
    const vm = createComponent();

    vm.$nextTick(() => {
      expect(vm.$el.getElementById('ide')).toBeTruthy();
    });
  });
});
