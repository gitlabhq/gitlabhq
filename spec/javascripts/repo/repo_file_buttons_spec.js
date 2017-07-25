import Vue from 'vue';
import repoFileButtons from '~/repo/repo_file_buttons.vue';

fdescribe('RepoFileButtons', () => {
  const RepoFileButtons = Vue.extend(repoFileButtons);

  function createComponent() {
    return new RepoFileButtons().$mount();
  }

  it('does not render if not isMini', () => {
    const vm = createComponent({});

    vm.$nextTick(() => {
      expect(vm.$el.getElementById('ide')).toBeTruthy();
    });
  });
});
