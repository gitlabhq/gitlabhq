import Vue from 'vue';
import repoFileOptions from '~/repo/components/repo_file_options.vue';

describe('RepoFileOptions', () => {
  const projectName = 'projectName';

  function createComponent(propsData) {
    const RepoFileOptions = Vue.extend(repoFileOptions);

    return new RepoFileOptions({
      propsData,
    }).$mount();
  }

  it('renders the title and new file/folder buttons if isMini is true', () => {
    const vm = createComponent({
      isMini: true,
      projectName,
    });

    expect(vm.$el.classList.contains('repo-file-options')).toBeTruthy();
    expect(vm.$el.querySelector('.title').textContent).toEqual(projectName);
    expect(vm.$el.querySelector('a[title="New File"]')).toBeTruthy();
    expect(vm.$el.querySelector('a[title="New Folder"]')).toBeTruthy();
  });

  it('does not render if isMini is false', () => {
    const vm = createComponent({
      isMini: false,
      projectName,
    });

    expect(vm.$el.innerHTML).toBeFalsy();
  });
});
