import Vue from 'vue';
import store from '~/ide/stores';
import List from '~/ide/components/merge_requests/list.vue';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';
import { mergeRequests } from '../../mock_data';
import { resetStore } from '../../helpers';

describe('IDE merge requests list', () => {
  const Component = Vue.extend(List);
  let vm;

  beforeEach(() => {
    vm = createComponentWithStore(Component, store, {});

    spyOn(vm, 'fetchMergeRequests');

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('calls fetch on mounted', () => {
    expect(vm.fetchMergeRequests).toHaveBeenCalledWith({
      search: '',
      type: '',
    });
  });

  it('renders loading icon', done => {
    vm.$store.state.mergeRequests.isLoading = true;

    vm.$nextTick(() => {
      expect(vm.$el.querySelector('.loading-container')).not.toBe(null);

      done();
    });
  });

  it('renders no search results text when search is not empty', done => {
    vm.search = 'testing';

    vm.$nextTick(() => {
      expect(vm.$el.textContent).toContain('No merge requests found');

      done();
    });
  });

  it('clicking on search type, sets currentSearchType and loads merge requests', done => {
    vm.onSearchFocus();

    vm.$nextTick()
      .then(() => {
        vm.$el.querySelector('li button').click();

        return vm.$nextTick();
      })
      .then(() => {
        expect(vm.currentSearchType).toEqual(vm.$options.searchTypes[0]);
        expect(vm.fetchMergeRequests).toHaveBeenCalledWith({
          type: vm.currentSearchType.type,
          search: '',
        });
      })
      .then(done)
      .catch(done.fail);
  });

  describe('with merge requests', () => {
    beforeEach(done => {
      vm.$store.state.mergeRequests.mergeRequests.push({
        ...mergeRequests[0],
        projectPathWithNamespace: 'gitlab-org/gitlab-ce',
      });

      vm.$nextTick(done);
    });

    it('renders list', () => {
      expect(vm.$el.querySelectorAll('li').length).toBe(1);
      expect(vm.$el.querySelector('li').textContent).toContain(mergeRequests[0].title);
    });
  });

  describe('searchMergeRequests', () => {
    beforeEach(() => {
      spyOn(vm, 'loadMergeRequests');

      jasmine.clock().install();
    });

    afterEach(() => {
      jasmine.clock().uninstall();
    });

    it('calls loadMergeRequests on input in search field', () => {
      const event = new Event('input');

      vm.$el.querySelector('input').dispatchEvent(event);

      jasmine.clock().tick(300);

      expect(vm.loadMergeRequests).toHaveBeenCalled();
    });
  });

  describe('onSearchFocus', () => {
    it('shows search types', done => {
      vm.$el.querySelector('input').dispatchEvent(new Event('focus'));

      expect(vm.hasSearchFocus).toBe(true);
      expect(vm.showSearchTypes).toBe(true);

      vm.$nextTick()
        .then(() => {
          const expectedSearchTypes = vm.$options.searchTypes.map(x => x.label);
          const renderedSearchTypes = Array.from(vm.$el.querySelectorAll('li'))
            .map(x => x.textContent.trim());

          expect(renderedSearchTypes).toEqual(expectedSearchTypes);
        })
        .then(done)
        .catch(done.fail);
    });

    it('does not show search types, if already has search value', () => {
      vm.search = 'lorem ipsum';
      vm.$el.querySelector('input').dispatchEvent(new Event('focus'));

      expect(vm.hasSearchFocus).toBe(true);
      expect(vm.showSearchTypes).toBe(false);
    });

    it('does not show search types, if already has a search type', () => {
      vm.currentSearchType = {};
      vm.$el.querySelector('input').dispatchEvent(new Event('focus'));

      expect(vm.hasSearchFocus).toBe(true);
      expect(vm.showSearchTypes).toBe(false);
    });

    it('resets hasSearchFocus when search changes', done => {
      vm.hasSearchFocus = true;
      vm.search = 'something else';

      vm.$nextTick()
        .then(() => {
          expect(vm.hasSearchFocus).toBe(false);
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
