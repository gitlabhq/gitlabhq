import Vue from 'vue';
import CompareVersionsComponent from '~/diffs/components/compare_versions.vue';
import { createStore } from '~/mr_notes/stores';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import diffsMockData from '../mock_data/merge_request_diffs';
import getDiffWithCommit from '../mock_data/diff_with_commit';

describe('CompareVersions', () => {
  let vm;
  const targetBranch = { branchName: 'tmp-wine-dev', versionIndex: -1 };

  beforeEach(() => {
    const store = createStore();

    store.state.diffs.addedLines = 10;
    store.state.diffs.removedLines = 20;
    store.state.diffs.diffFiles.push('test');

    vm = createComponentWithStore(Vue.extend(CompareVersionsComponent), store, {
      mergeRequestDiffs: diffsMockData,
      mergeRequestDiff: diffsMockData[0],
      targetBranch,
    }).$mount();
  });

  describe('template', () => {
    it('should render Tree List toggle button with correct attribute values', () => {
      const treeListBtn = vm.$el.querySelector('.js-toggle-tree-list');

      expect(treeListBtn).not.toBeNull();
      expect(treeListBtn.dataset.originalTitle).toBe('Hide file browser');
      expect(treeListBtn.querySelectorAll('svg use').length).not.toBe(0);
      expect(treeListBtn.querySelector('svg use').getAttribute('xlink:href')).toContain(
        '#collapse-left',
      );
    });

    it('should render comparison dropdowns with correct values', () => {
      const sourceDropdown = vm.$el.querySelector('.mr-version-dropdown');
      const targetDropdown = vm.$el.querySelector('.mr-version-compare-dropdown');

      expect(sourceDropdown).not.toBeNull();
      expect(targetDropdown).not.toBeNull();
      expect(sourceDropdown.querySelector('a span').innerHTML).toContain('latest version');
      expect(targetDropdown.querySelector('a span').innerHTML).toContain(targetBranch.branchName);
    });

    it('should not render comparison dropdowns if no mergeRequestDiffs are specified', () => {
      vm.mergeRequestDiffs = [];

      vm.$nextTick(() => {
        const sourceDropdown = vm.$el.querySelector('.mr-version-dropdown');
        const targetDropdown = vm.$el.querySelector('.mr-version-compare-dropdown');

        expect(sourceDropdown).toBeNull();
        expect(targetDropdown).toBeNull();
      });
    });

    it('should render view types buttons with correct values', () => {
      const inlineBtn = vm.$el.querySelector('#inline-diff-btn');
      const parallelBtn = vm.$el.querySelector('#parallel-diff-btn');

      expect(inlineBtn).not.toBeNull();
      expect(parallelBtn).not.toBeNull();
      expect(inlineBtn.dataset.viewType).toEqual('inline');
      expect(parallelBtn.dataset.viewType).toEqual('parallel');
      expect(inlineBtn.innerHTML).toContain('Inline');
      expect(parallelBtn.innerHTML).toContain('Side-by-side');
    });

    it('adds container-limiting classes when showFileTree is false with inline diffs', () => {
      vm.isLimitedContainer = true;

      vm.$nextTick(() => {
        const limitedContainer = vm.$el.querySelector('.container-limited.limit-container-width');

        expect(limitedContainer).not.toBeNull();
      });
    });

    it('does not add container-limiting classes when showFileTree is false with inline diffs', () => {
      vm.isLimitedContainer = false;

      vm.$nextTick(() => {
        const limitedContainer = vm.$el.querySelector('.container-limited.limit-container-width');

        expect(limitedContainer).toBeNull();
      });
    });
  });

  describe('setInlineDiffViewType', () => {
    it('should persist the view type in the url', () => {
      const viewTypeBtn = vm.$el.querySelector('#inline-diff-btn');
      viewTypeBtn.click();

      expect(window.location.toString()).toContain('?view=inline');
    });
  });

  describe('setParallelDiffViewType', () => {
    it('should persist the view type in the url', () => {
      const viewTypeBtn = vm.$el.querySelector('#parallel-diff-btn');
      viewTypeBtn.click();

      expect(window.location.toString()).toContain('?view=parallel');
    });
  });

  describe('comparableDiffs', () => {
    it('should not contain the first item in the mergeRequestDiffs property', () => {
      const { comparableDiffs } = vm;
      const comparableDiffsMock = diffsMockData.slice(1);

      expect(comparableDiffs).toEqual(comparableDiffsMock);
    });
  });

  describe('baseVersionPath', () => {
    it('should be set correctly from mergeRequestDiff', () => {
      expect(vm.baseVersionPath).toEqual(vm.mergeRequestDiff.base_version_path);
    });
  });

  describe('commit', () => {
    beforeEach(done => {
      vm.$store.state.diffs.commit = getDiffWithCommit().commit;
      vm.mergeRequestDiffs = [];

      vm.$nextTick(done);
    });

    it('renders latest version button', () => {
      expect(vm.$el.querySelector('.js-latest-version').textContent.trim()).toBe(
        'Show latest version',
      );
    });

    it('renders short commit ID', () => {
      expect(vm.$el.textContent).toContain('Viewing commit');
      expect(vm.$el.textContent).toContain(vm.commit.short_id);
    });
  });
});
