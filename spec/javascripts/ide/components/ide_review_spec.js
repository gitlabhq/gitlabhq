import Vue from 'vue';
import IdeReview from '~/ide/components/ide_review.vue';
import store from '~/ide/stores';
import { createComponentWithStore } from '../../helpers/vue_mount_component_helper';
import { trimText } from '../../helpers/vue_component_helper';
import { resetStore, file } from '../helpers';
import { projectData } from '../mock_data';

describe('IDE review mode', () => {
  const Component = Vue.extend(IdeReview);
  let vm;

  beforeEach(() => {
    store.state.currentProjectId = 'abcproject';
    store.state.currentBranchId = 'master';
    store.state.projects.abcproject = Object.assign({}, projectData);
    Vue.set(store.state.trees, 'abcproject/master', {
      tree: [file('fileName')],
      loading: false,
    });

    vm = createComponentWithStore(Component, store).$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders list of files', () => {
    expect(vm.$el.textContent).toContain('fileName');
  });

  describe('merge request', () => {
    beforeEach(done => {
      store.state.currentMergeRequestId = '1';
      store.state.projects.abcproject.mergeRequests['1'] = {
        iid: 123,
        web_url: 'testing123',
      };

      vm.$nextTick(done);
    });

    it('renders edit dropdown', () => {
      expect(vm.$el.querySelector('.btn')).not.toBe(null);
    });

    it('renders merge request link & IID', () => {
      const link = vm.$el.querySelector('.ide-review-sub-header');

      expect(link.querySelector('a').getAttribute('href')).toBe('testing123');
      expect(trimText(link.textContent)).toBe('Merge request (!123)');
    });

    it('changes text to latest changes when viewer is not mrdiff', done => {
      store.state.viewer = 'diff';

      vm.$nextTick(() => {
        expect(trimText(vm.$el.querySelector('.ide-review-sub-header').textContent)).toBe(
          'Latest changes',
        );

        done();
      });
    });
  });
});
