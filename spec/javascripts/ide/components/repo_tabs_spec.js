import Vue from 'vue';
import repoTabs from '~/ide/components/repo_tabs.vue';
import createComponent from '../../helpers/vue_mount_component_helper';
import { file } from '../helpers';

describe('RepoTabs', () => {
  const openedFiles = [file('open1'), file('open2')];
  const RepoTabs = Vue.extend(repoTabs);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  it('renders a list of tabs', done => {
    vm = createComponent(RepoTabs, {
      files: openedFiles,
      viewer: 'editor',
      hasChanges: false,
      activeFile: file('activeFile'),
      hasMergeRequest: false,
    });
    openedFiles[0].active = true;

    vm.$nextTick(() => {
      const tabs = [...vm.$el.querySelectorAll('.multi-file-tab')];

      expect(tabs.length).toEqual(2);
      expect(tabs[0].classList.contains('active')).toEqual(true);
      expect(tabs[1].classList.contains('active')).toEqual(false);

      done();
    });
  });

  describe('updated', () => {
    it('sets showShadow as true when scroll width is larger than width', done => {
      const el = document.createElement('div');
      el.innerHTML = '<div id="test-app"></div>';
      document.body.appendChild(el);

      const style = document.createElement('style');
      style.innerText = `
        .multi-file-tabs {
          width: 100px;
        }

        .multi-file-tabs .list-unstyled {
          display: flex;
          overflow-x: auto;
        }
      `;
      document.head.appendChild(style);

      vm = createComponent(
        RepoTabs,
        {
          files: [],
          viewer: 'editor',
          hasChanges: false,
          activeFile: file('activeFile'),
          hasMergeRequest: false,
        },
        '#test-app',
      );

      vm
        .$nextTick()
        .then(() => {
          expect(vm.showShadow).toEqual(false);

          vm.files = openedFiles;
        })
        .then(vm.$nextTick)
        .then(() => {
          expect(vm.showShadow).toEqual(true);

          style.remove();
          el.remove();
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
