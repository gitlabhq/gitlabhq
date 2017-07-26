import Vue from 'vue';
import repoFile from '~/repo/repo_file.vue';

describe('RepoFile', () => {
  const file = {
    icon: 'icon',
    url: 'url',
    name: 'name',
    lastCommitMessage: 'message',
    lastCommitUpdate: 'update',
    level: 10,
  };
  const activeFile = {
    url: 'url',
  };

  function createComponent(propsData) {
    const RepoFile = Vue.extend(repoFile);

    return new RepoFile({
      propsData,
    }).$mount();
  }

  it('renders link, icon, name and last commit details', () => {
    const vm = createComponent({
      file,
      activeFile,
    });
    const icon = vm.$el.querySelector(`.${file.icon}`);
    const name = vm.$el.querySelector('.repo-file-name');
    const commitMessage = vm.$el.querySelector('.commit-message');
    const commitUpdate = vm.$el.querySelector('.commit-update');

    expect(vm.$el.innerHTML).toBeTruthy();
    expect(vm.$el.classList.contains('active')).toBeTruthy();
    expect(icon).toBeTruthy();
    expect(icon.style.marginLeft).toEqual('100px');
    expect(name).toBeTruthy();
    expect(name.title).toEqual(file.url);
    expect(name.href).toMatch(`/${file.url}`);
    expect(name.textContent).toEqual(file.name);
    expect(commitMessage).toBeTruthy();
    expect(commitMessage.textContent).toBe(file.lastCommitMessage);
    expect(commitUpdate).toBeTruthy();
    expect(commitUpdate.textContent).toBe(file.lastCommitUpdate);
  });

  it('does render if hasFiles is true and is loading tree', () => {
    const vm = createComponent({
      file,
      activeFile,
      loading: {
        tree: true,
      },
      hasFiles: true,
    });

    expect(vm.$el.innerHTML).toBeTruthy();
  });

  it('does not render if loading tree', () => {
    const vm = createComponent({
      file,
      activeFile,
      loading: {
        tree: true,
      },
    });

    expect(vm.$el.innerHTML).toBeFalsy();
  });

  it('does not render commit message and datetime if mini', () => {
    const vm = createComponent({
      file,
      activeFile,
      isMini: true,
    });
    const commitMessage = vm.$el.querySelector('.commit-message');
    const commitUpdate = vm.$el.querySelector('.commit-update');

    expect(commitMessage).toBeFalsy();
    expect(commitUpdate).toBeFalsy();
  });

  it('does not set active class if file is active file', () => {
    const vm = createComponent({
      file,
      activeFile: {},
    });

    expect(vm.$el.classList.contains('active')).toBeFalsy();
  });

  it('fires linkClicked when the link is clicked', () => {
    const vm = createComponent({
      file,
      activeFile,
    });

    spyOn(vm, 'linkClicked');

    vm.$el.querySelector('.repo-file-name').click();

    expect(vm.linkClicked).toHaveBeenCalledWith(file);
  });
});
