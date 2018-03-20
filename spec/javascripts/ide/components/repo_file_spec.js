import Vue from 'vue';
import store from '~/ide/stores';
import repoFile from '~/ide/components/repo_file.vue';
import router from '~/ide/ide_router';
import { createComponentWithStore } from '../../helpers/vue_mount_component_helper';
import { file } from '../helpers';

describe('RepoFile', () => {
  let vm;

  function createComponent(propsData) {
    const RepoFile = Vue.extend(repoFile);

    vm = createComponentWithStore(RepoFile, store, propsData);

    vm.$mount();
  }

  afterEach(() => {
    vm.$destroy();
  });

  it('renders link, icon and name', () => {
    createComponent({
      file: file('t4'),
      level: 0,
    });

    const name = vm.$el.querySelector('.ide-file-name');

    expect(name.href).toMatch('');
    expect(name.textContent.trim()).toEqual(vm.file.name);
  });

  it('fires clickFile when the link is clicked', done => {
    spyOn(router, 'push');
    createComponent({
      file: file('t3'),
      level: 0,
    });

    vm.$el.querySelector('.file-name').click();

    setTimeout(() => {
      expect(router.push).toHaveBeenCalledWith(`/project${vm.file.url}`);

      done();
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

      createComponent({
        file: f,
        level: 0,
      });
    });

    it('renders lock icon', () => {
      expect(vm.$el.querySelector('.file-status-icon')).not.toBeNull();
    });

    it('renders a tooltip', () => {
      expect(
        vm.$el.querySelector('.ide-file-name span:nth-child(2)').dataset
          .originalTitle,
      ).toContain('Locked by testuser');
    });
  });
});
