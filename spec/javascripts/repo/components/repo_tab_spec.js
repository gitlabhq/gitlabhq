import Vue from 'vue';
import store from '~/repo/stores';
import repoTab from '~/repo/components/repo_tab.vue';
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
    const close = vm.$el.querySelector('.close-btn');
    const name = vm.$el.querySelector(`a[title="${vm.tab.url}"]`);

    expect(close.querySelector('.fa-times')).toBeTruthy();
    expect(name.textContent.trim()).toEqual(vm.tab.name);
  });

  it('calls setFileActive when clicking tab', () => {
    vm = createComponent({
      tab: file(),
    });

    spyOn(vm, 'setFileActive');

    vm.$el.click();

    expect(vm.setFileActive).toHaveBeenCalledWith(vm.tab);
  });

  it('calls closeFile when clicking close button', () => {
    vm = createComponent({
      tab: file(),
    });

    spyOn(vm, 'closeFile');

    vm.$el.querySelector('.close-btn').click();

    expect(vm.closeFile).toHaveBeenCalledWith({ file: vm.tab });
  });

  it('renders an fa-circle icon if tab is changed', () => {
    const tab = file();
    tab.changed = true;
    vm = createComponent({
      tab,
    });

    expect(vm.$el.querySelector('.close-btn .fa-circle')).toBeTruthy();
  });

  describe('methods', () => {
    describe('closeTab', () => {
      it('does not close tab if is changed', (done) => {
        const tab = file();
        tab.changed = true;
        tab.opened = true;
        vm = createComponent({
          tab,
        });
        vm.$store.state.openFiles.push(tab);
        vm.$store.dispatch('setFileActive', tab);

        vm.$el.querySelector('.close-btn').click();

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

        vm.$el.querySelector('.close-btn').click();

        vm.$nextTick(() => {
          expect(tab.opened).toBeFalsy();

          done();
        });
      });
    });
  });
});
