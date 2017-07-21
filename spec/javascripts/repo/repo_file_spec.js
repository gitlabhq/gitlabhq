import Vue from 'vue';
import repoFile from '~/repo/repo_file.vue';

describe('RepoFile', () => {
  const RepoFile = Vue.extend(repoFile);
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
    return new RepoFile({
      propsData,
    }).$mount();
  }

  it('renders if not loading tree and has files', () => {
    const vm = createComponent({
      file,
      activeFile,
      isMini: false,
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

  it('does not render if loading tree or has no files', () => {});

  it('does not render commit message and datetime if mini', () => {});

  it('does not set active class if file is active file', () => {});
});
