import Vue from 'vue';
import store from '~/ide/stores';
import repoTab from '~/ide/components/repo_tab.vue';
import { file, resetStore } from '../helpers';

describe('RepoTab', () => {
  let vm;

  function createComponent(propsData) {
    const RepoTab = Vue.extend(repoTab);

    return new RepoTab({
      store,
      propsData,
    }).$mount();
  }

  afterEach(() => {
    resetStore(vm.$store);
  });

  it('renders a close link and a name link', () => {
    vm = createComponent({
      tab: file(),
    });
    vm.$store.state.openFiles.push(vm.tab);
    const close = vm.$el.querySelector('.multi-file-tab-close');
    const name = vm.$el.querySelector(`[title="${vm.tab.url}"]`);

    expect(close.querySelector('.fa-times')).toBeTruthy();
    expect(name.textContent.trim()).toEqual(vm.tab.name);
  });

  it('fires clickFile when the link is clicked', () => {
    vm = createComponent({
      tab: file(),
    });

    spyOn(vm, 'clickFile');

    vm.$el.click();

    expect(vm.clickFile).toHaveBeenCalledWith(vm.tab);
  });

  it('calls closeFile when clicking close button', () => {
    vm = createComponent({
      tab: file(),
    });

    spyOn(vm, 'closeFile');

    vm.$el.querySelector('.multi-file-tab-close').click();

    expect(vm.closeFile).toHaveBeenCalledWith({ file: vm.tab });
  });

  it('renders an fa-circle icon if tab is changed', () => {
    const tab = file('changedFile');
    tab.changed = true;
    vm = createComponent({
      tab,
    });

    expect(vm.$el.querySelector('.multi-file-tab-close .fa-circle')).not.toBeNull();
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
        tab: f,
      });
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('renders lock icon', () => {
      expect(vm.$el.querySelector('.file-status-icon')).not.toBeNull();
    });

    it('renders a tooltip', () => {
      expect(vm.$el.querySelector('span:nth-child(2)').dataset.originalTitle).toContain('Locked by testuser');
    });
  });

  describe('methods', () => {
    describe('closeTab', () => {
      it('does not close tab if is changed', (done) => {
        const tab = file('closeFile');
        tab.changed = true;
        tab.opened = true;
        vm = createComponent({
          tab,
        });
        vm.$store.state.openFiles.push(tab);
        vm.$store.dispatch('setFileActive', tab);

        vm.$el.querySelector('.multi-file-tab-close').click();

        vm.$nextTick(() => {
          expect(tab.opened).toBeTruthy();

          done();
        });
      });

      it('closes tab when clicking close btn', (done) => {
        const tab = file('lose');
        tab.opened = true;
        vm = createComponent({
          tab,
        });
        vm.$store.state.openFiles.push(tab);
        vm.$store.dispatch('setFileActive', tab);

        vm.$el.querySelector('.multi-file-tab-close').click();

        vm.$nextTick(() => {
          expect(tab.opened).toBeFalsy();

          done();
        });
      });
    });
  });
});
