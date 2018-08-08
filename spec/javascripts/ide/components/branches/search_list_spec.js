import Vue from 'vue';
import store from '~/ide/stores';
import * as types from '~/ide/stores/modules/branches/mutation_types';
import List from '~/ide/components/branches/search_list.vue';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';
import { branches as testBranches } from '../../mock_data';
import { resetStore } from '../../helpers';

describe('IDE branches search list', () => {
  const Component = Vue.extend(List);
  let vm;

  beforeEach(() => {
    vm = createComponentWithStore(Component, store, {});

    spyOn(vm, 'fetchBranches');

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(store);
  });

  it('calls fetch on mounted', () => {
    expect(vm.fetchBranches).toHaveBeenCalledWith({
      search: '',
    });
  });

  it('renders loading icon', done => {
    vm.$store.state.branches.isLoading = true;

    vm.$nextTick()
      .then(() => {
        expect(vm.$el).toContainElement('.loading-container');
      })
      .then(done)
      .catch(done.fail);
  });

  it('renders branches not found when search is not empty', done => {
    vm.search = 'testing';

    vm.$nextTick(() => {
      expect(vm.$el).toContainText('No branches found');

      done();
    });
  });

  describe('with branches', () => {
    const currentBranch = testBranches[1];

    beforeEach(done => {
      vm.$store.state.currentBranchId = currentBranch.name;
      vm.$store.commit(`branches/${types.RECEIVE_BRANCHES_SUCCESS}`, testBranches);

      vm.$nextTick(done);
    });

    it('renders list', () => {
      const elementText = Array.from(vm.$el.querySelectorAll('li strong'))
        .map(x => x.textContent.trim());

      expect(elementText).toEqual(testBranches.map(x => x.name));
    });

    it('renders check next to active branch', () => {
      const checkedText = Array.from(vm.$el.querySelectorAll('li'))
        .filter(x => x.querySelector('.ide-search-list-current-icon svg'))
        .map(x => x.querySelector('strong').textContent.trim());

      expect(checkedText).toEqual([currentBranch.name]);
    });
  });
});
