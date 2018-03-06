import Vue from 'vue';
import store from 'ee/ide/stores';
import repoPrevDirectory from 'ee/ide/components/repo_prev_directory.vue';
import { resetStore } from '../helpers';

describe('RepoPrevDirectory', () => {
  let vm;
  const parentLink = 'parent';
  function createComponent() {
    const RepoPrevDirectory = Vue.extend(repoPrevDirectory);

    const comp = new RepoPrevDirectory({
      store,
    });

    comp.$store.state.parentTreeUrl = parentLink;

    return comp.$mount();
  }

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders a prev dir link', () => {
    const link = vm.$el.querySelector('a');

    expect(link.href).toMatch(`/${parentLink}`);
    expect(link.textContent).toEqual('...');
  });

  it('clicking row triggers getTreeData', () => {
    spyOn(vm, 'getTreeData');

    vm.$el.querySelector('td').click();

    expect(vm.getTreeData).toHaveBeenCalledWith({ endpoint: parentLink });
  });
});
