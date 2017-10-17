import Vue from 'vue';
import repoFile from '~/repo/components/repo_file.vue';
import RepoStore from '~/repo/stores/repo_store';
import eventHub from '~/repo/event_hub';
import { file } from '../mock_data';

describe('RepoFile', () => {
  const updated = 'updated';
  const otherFile = {
    html: '<p class="file-content">html</p>',
    pageTitle: 'otherpageTitle',
  };

  function createComponent(propsData) {
    const RepoFile = Vue.extend(repoFile);

    return new RepoFile({
      propsData,
    }).$mount();
  }

  beforeEach(() => {
    RepoStore.openedFiles = [];
  });

  it('renders link, icon, name and last commit details', () => {
    const RepoFile = Vue.extend(repoFile);
    const vm = new RepoFile({
      propsData: {
        file: file(),
      },
    });
    spyOn(vm, 'timeFormated').and.returnValue(updated);
    vm.$mount();

    const name = vm.$el.querySelector('.repo-file-name');
    const fileIcon = vm.$el.querySelector('.file-icon');

    expect(vm.$el.querySelector(`.${vm.file.icon}`).style.marginLeft).toEqual('0px');
    expect(name.href).toMatch(`/${vm.file.url}`);
    expect(name.textContent.trim()).toEqual(vm.file.name);
    expect(vm.$el.querySelector('.commit-message').textContent.trim()).toBe(vm.file.lastCommit.message);
    expect(vm.$el.querySelector('.commit-update').textContent.trim()).toBe(updated);
    expect(fileIcon.classList.contains(vm.file.icon)).toBeTruthy();
    expect(fileIcon.style.marginLeft).toEqual(`${vm.file.level * 10}px`);
  });

  it('does render if hasFiles is true and is loading tree', () => {
    const vm = createComponent({
      file: file(),
    });

    expect(vm.$el.querySelector('.fa-spin.fa-spinner')).toBeFalsy();
  });

  it('sets the document title correctly', () => {
    RepoStore.setActiveFiles(otherFile);

    expect(document.title.trim()).toEqual(otherFile.pageTitle);
  });

  it('renders a spinner if the file is loading', () => {
    const f = file();
    f.loading = true;
    const vm = createComponent({
      file: f,
    });

    expect(vm.$el.querySelector('.fa-spin.fa-spinner')).not.toBeNull();
    expect(vm.$el.querySelector('.fa-spin.fa-spinner').style.marginLeft).toEqual(`${vm.file.level * 16}px`);
  });

  it('does not render commit message and datetime if mini', () => {
    RepoStore.openedFiles.push(file());

    const vm = createComponent({
      file: file(),
    });

    expect(vm.$el.querySelector('.commit-message')).toBeFalsy();
    expect(vm.$el.querySelector('.commit-update')).toBeFalsy();
  });

  it('fires linkClicked when the link is clicked', () => {
    const vm = createComponent({
      file: file(),
    });

    spyOn(vm, 'linkClicked');

    vm.$el.click();

    expect(vm.linkClicked).toHaveBeenCalledWith(vm.file);
  });

  describe('methods', () => {
    describe('linkClicked', () => {
      it('$emits fileNameClicked with file obj', () => {
        spyOn(eventHub, '$emit');

        const vm = createComponent({
          file: file(),
        });

        vm.linkClicked(vm.file);

        expect(eventHub.$emit).toHaveBeenCalledWith('fileNameClicked', vm.file);
      });
    });
  });
});
