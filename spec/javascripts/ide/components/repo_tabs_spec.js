import Vue from 'vue';
import store from 'ee/ide/stores';
import repoTabs from 'ee/ide/components/repo_tabs.vue';
import { file, resetStore } from '../helpers';

describe('RepoTabs', () => {
  const openedFiles = [file('open1'), file('open2')];
  let vm;

  function createComponent(el = null) {
    const RepoTabs = Vue.extend(repoTabs);

    return new RepoTabs({
      store,
    }).$mount(el);
  }

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders a list of tabs', (done) => {
    vm = createComponent();
    openedFiles[0].active = true;
    vm.$store.state.openFiles = openedFiles;

    vm.$nextTick(() => {
      const tabs = [...vm.$el.querySelectorAll('.multi-file-tab')];

      expect(tabs.length).toEqual(2);
      expect(tabs[0].classList.contains('active')).toBeTruthy();
      expect(tabs[1].classList.contains('active')).toBeFalsy();

      done();
    });
  });

  describe('updated', () => {
    it('sets showShadow as true when scroll width is larger than width', (done) => {
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

      vm = createComponent('#test-app');
      openedFiles[0].active = true;

      vm.$nextTick()
        .then(() => {
          expect(vm.showShadow).toBeFalsy();

          vm.$store.state.openFiles = openedFiles;
        })
        .then(vm.$nextTick)
        .then(() => {
          expect(vm.showShadow).toBeTruthy();

          style.remove();
          el.remove();
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
