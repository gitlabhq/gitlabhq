import Vue from 'vue';
import store from 'ee/ide/stores';
import repoFile from 'ee/ide/components/repo_file.vue';
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
        file: file('t4'),
      },
    });
    spyOn(vm, 'timeFormated').and.returnValue(updated);
    vm.$mount();

    const name = vm.$el.querySelector('.ide-file-name');

    expect(name.href).toMatch('');
    expect(name.textContent.trim()).toEqual(vm.file.name);
  });

  it('does render if hasFiles is true and is loading tree', () => {
    vm = createComponent({
      file: file('t1'),
    });

    expect(vm.$el.querySelector('.fa-spin.fa-spinner')).toBeFalsy();
  });

  it('does not render commit message and datetime if mini', (done) => {
    vm = createComponent({
      file: file('t2'),
    });
    vm.$store.state.openFiles.push(vm.file);

    vm.$nextTick(() => {
      expect(vm.$el.querySelector('.commit-message')).toBeFalsy();
      expect(vm.$el.querySelector('.commit-update')).toBeFalsy();

      done();
    });
  });

  it('fires clickFile when the link is clicked', () => {
    vm = createComponent({
      file: file('t3'),
    });

    spyOn(vm, 'clickFile');

    vm.$el.querySelector('.file-name').click();

    expect(vm.clickFile).toHaveBeenCalledWith(vm.file);
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
  });

  describe('locked file', () => {
    let f;

    beforeEach(() => {
      f = file('locked file');
      f.file_lock = {
        user: {
          name: 'testuser',
          updated_at: new Date(),
        },
      };

      vm = createComponent({
        file: f,
      });
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('renders lock icon', () => {
      expect(vm.$el.querySelector('.file-status-icon')).not.toBeNull();
    });

    it('renders a tooltip', () => {
      expect(vm.$el.querySelector('.ide-file-name span:nth-child(2)').dataset.originalTitle).toContain('Locked by testuser');
    });
  });
});
