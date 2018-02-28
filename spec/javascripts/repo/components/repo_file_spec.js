import Vue from 'vue';
import store from '~/repo/stores';
import repoFile from '~/repo/components/repo_file.vue';
import { file, resetStore } from '../helpers';

describe('RepoFile', () => {
  const updated = 'updated';
  let vm;

  function createComponent(propsData) {
    const RepoFile = Vue.extend(repoFile);

    return new RepoFile({
      store,
      propsData,
    }).$mount();
  }

  afterEach(() => {
    resetStore(vm.$store);
  });

  it('renders link, icon and name', () => {
    const RepoFile = Vue.extend(repoFile);
    vm = new RepoFile({
      store,
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
    expect(fileIcon.classList.contains(vm.file.icon)).toBeTruthy();
    expect(fileIcon.style.marginLeft).toEqual(`${vm.file.level * 10}px`);
    expect(vm.$el.querySelectorAll('.animation-container').length).toBe(2);
  });

  it('does render if hasFiles is true and is loading tree', () => {
    vm = createComponent({
      file: file(),
    });

    expect(vm.$el.querySelector('.fa-spin.fa-spinner')).toBeFalsy();
  });

  it('renders a spinner if the file is loading', () => {
    const f = file();
    f.loading = true;
    vm = createComponent({
      file: f,
    });

    expect(vm.$el.querySelector('.fa-spin.fa-spinner')).not.toBeNull();
    expect(vm.$el.querySelector('.fa-spin.fa-spinner').style.marginLeft).toEqual(`${vm.file.level * 16}px`);
  });

  it('does not render commit message and datetime if mini', (done) => {
    vm = createComponent({
      file: file(),
    });
    vm.$store.state.openFiles.push(vm.file);

    vm.$nextTick(() => {
      expect(vm.$el.querySelector('.commit-message')).toBeFalsy();
      expect(vm.$el.querySelector('.commit-update')).toBeFalsy();

      done();
    });
  });

  it('fires clickedTreeRow when the link is clicked', () => {
    vm = createComponent({
      file: file(),
    });

    spyOn(vm, 'clickedTreeRow');

    vm.$el.click();

    expect(vm.clickedTreeRow).toHaveBeenCalledWith(vm.file);
  });

  describe('submodule', () => {
    let f;

    beforeEach(() => {
      f = file('submodule name', '123456789');
      f.type = 'submodule';

      vm = createComponent({
        file: f,
      });
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('renders submodule short ID', () => {
      expect(vm.$el.querySelector('.commit-sha').textContent.trim()).toBe('12345678');
    });

    it('renders ID next to submodule name', () => {
      expect(vm.$el.querySelector('td').textContent.replace(/\s+/g, ' ')).toContain('submodule name @ 12345678');
    });
  });
});
