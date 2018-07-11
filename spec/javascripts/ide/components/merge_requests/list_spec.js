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
    vm = createComponentWithStore(Component, store, {
      type: 'created',
      emptyText: 'empty text',
    });

    spyOn(vm, 'fetchMergeRequests');

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('calls fetch on mounted', () => {
    expect(vm.fetchMergeRequests).toHaveBeenCalledWith({
      type: 'created',
      search: '',
    });
  });

  it('renders loading icon', done => {
    vm.$store.state.mergeRequests.created.isLoading = true;

    vm.$nextTick(() => {
      expect(vm.$el.querySelector('.loading-container')).not.toBe(null);

      done();
    });
  });

  it('renders empty text when no merge requests exist', () => {
    expect(vm.$el.textContent).toContain('empty text');
  });

  it('renders no search results text when search is not empty', done => {
    vm.search = 'testing';

    vm.$nextTick(() => {
      expect(vm.$el.textContent).toContain('No merge requests found');

      done();
    });
  });

  describe('with merge requests', () => {
    beforeEach(done => {
      vm.$store.state.mergeRequests.created.mergeRequests.push({
        ...mergeRequests[0],
        projectPathWithNamespace: 'gitlab-org/gitlab-ce',
      });

      vm.$nextTick(done);
    });

    it('renders list', () => {
      expect(vm.$el.querySelectorAll('li').length).toBe(1);
      expect(vm.$el.querySelector('li').textContent).toContain(mergeRequests[0].title);
    });

    it('calls openMergeRequest when clicking merge request', done => {
      spyOn(vm, 'openMergeRequest');
      vm.$el.querySelector('li button').click();

      vm.$nextTick(() => {
        expect(vm.openMergeRequest).toHaveBeenCalledWith({
          projectPath: 'gitlab-org/gitlab-ce',
          id: 1,
        });

        done();
      });
    });
  });

  describe('focusSearch', () => {
    it('focuses search input when loading is false', done => {
      spyOn(vm.$refs.searchInput, 'focus');

      vm.$store.state.mergeRequests.created.isLoading = false;
      vm.focusSearch();

      vm.$nextTick(() => {
        expect(vm.$refs.searchInput.focus).toHaveBeenCalled();

        done();
      });
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
});
