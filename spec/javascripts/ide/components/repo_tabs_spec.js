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
      expect(tabs[0].parentNode.classList.contains('active')).toEqual(true);
      expect(tabs[1].parentNode.classList.contains('active')).toEqual(false);

      done();
    });
  });
});
