import Vue from 'vue';
import repoFile from '~/repo/components/repo_file.vue';

describe('RepoFile', () => {
  const updated = 'updated';
  const file = {
    icon: 'icon',
    url: 'url',
    name: 'name',
    lastCommitMessage: 'message',
    lastCommitUpdate: Date.now(),
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

  beforeEach(() => {
    spyOn(repoFile.mixins[0].methods, 'timeFormated').and.returnValue(updated);
  });

  it('renders link, icon, name and last commit details', () => {
    const vm = createComponent({
      file,
      activeFile,
    });
    const name = vm.$el.querySelector('.repo-file-name');
    const fileIcon = vm.$el.querySelector('.file-icon');

    expect(vm.$el.classList.contains('active')).toBeTruthy();
    expect(vm.$el.querySelector(`.${file.icon}`).style.marginLeft).toEqual('100px');
    expect(name.title).toEqual(file.url);
    expect(name.href).toMatch(`/${file.url}`);
    expect(name.textContent.trim()).toEqual(file.name);
    expect(vm.$el.querySelector('.commit-message').textContent.trim()).toBe(file.lastCommitMessage);
    expect(vm.$el.querySelector('.commit-update').textContent.trim()).toBe(updated);
    expect(fileIcon.classList.contains(file.icon)).toBeTruthy();
    expect(fileIcon.style.marginLeft).toEqual(`${file.level * 10}px`);
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
    expect(vm.$el.querySelector('.fa-spin.fa-spinner')).toBeFalsy();
  });

  it('renders a spinner if the file is loading', () => {
    file.loading = true;
    const vm = createComponent({
      file,
      activeFile,
      loading: {
        tree: true,
      },
      hasFiles: true,
    });

    expect(vm.$el.innerHTML).toBeTruthy();
    expect(vm.$el.querySelector('.fa-spin.fa-spinner').style.marginLeft).toEqual(`${file.level * 10}px`);
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

    expect(vm.$el.querySelector('.commit-message')).toBeFalsy();
    expect(vm.$el.querySelector('.commit-update')).toBeFalsy();
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

  describe('methods', () => {
    describe('linkClicked', () => {
      const vm = jasmine.createSpyObj('vm', ['$emit']);

      it('$emits linkclicked with file obj', () => {
        const theFile = {};

        repoFile.methods.linkClicked.call(vm, theFile);

        expect(vm.$emit).toHaveBeenCalledWith('linkclicked', theFile);
      });
    });
  });
});
