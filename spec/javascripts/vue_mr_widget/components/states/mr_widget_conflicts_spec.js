import $ from 'jquery';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import ConflictsComponent from '~/vue_merge_request_widget/components/states/mr_widget_conflicts.vue';
import { removeBreakLine } from 'spec/helpers/text_helper';

describe('MRWidgetConflicts', () => {
  let vm;
  const path = '/conflicts';

  function createComponent(propsData = {}) {
    const localVue = createLocalVue();

    vm = shallowMount(localVue.extend(ConflictsComponent), {
      propsData,
    });
  }

  beforeEach(() => {
    spyOn($.fn, 'popover').and.callThrough();
  });

  afterEach(() => {
    vm.destroy();
  });

  describe('when allowed to merge', () => {
    beforeEach(() => {
      createComponent({
        mr: {
          canMerge: true,
          conflictResolutionPath: path,
          conflictsDocsPath: '',
        },
      });
    });

    it('should tell you about conflicts without bothering other people', () => {
      expect(vm.text()).toContain('There are merge conflicts');
      expect(vm.text()).not.toContain('ask someone with write access');
    });

    it('should allow you to resolve the conflicts', () => {
      const resolveButton = vm.find('.js-resolve-conflicts-button');

      expect(resolveButton.text()).toContain('Resolve conflicts');
      expect(resolveButton.attributes('href')).toEqual(path);
    });

    it('should have merge buttons', () => {
      const mergeLocallyButton = vm.find('.js-merge-locally-button');

      expect(mergeLocallyButton.text()).toContain('Merge locally');
    });
  });

  describe('when user does not have permission to merge', () => {
    it('should show proper message', () => {
      createComponent({
        mr: {
          canMerge: false,
          conflictsDocsPath: '',
        },
      });

      expect(
        vm
          .text()
          .trim()
          .replace(/\s\s+/g, ' '),
      ).toContain('ask someone with write access');
    });

    it('should not have action buttons', () => {
      createComponent({
        mr: {
          canMerge: false,
          conflictsDocsPath: '',
        },
      });

      expect(vm.contains('.js-resolve-conflicts-button')).toBe(false);
      expect(vm.contains('.js-merge-locally-button')).toBe(false);
    });

    it('should not have resolve button when no conflict resolution path', () => {
      createComponent({
        mr: {
          canMerge: true,
          conflictResolutionPath: null,
          conflictsDocsPath: '',
        },
      });

      expect(vm.contains('.js-resolve-conflicts-button')).toBe(false);
    });
  });

  describe('when fast-forward or semi-linear merge enabled', () => {
    it('should tell you to rebase locally', () => {
      createComponent({
        mr: {
          shouldBeRebased: true,
          conflictsDocsPath: '',
        },
      });

      expect(removeBreakLine(vm.text()).trim()).toContain(
        'Fast-forward merge is not possible. To merge this request, first rebase locally.',
      );
    });
  });

  describe('when source branch protected', () => {
    beforeEach(() => {
      createComponent({
        mr: {
          canMerge: true,
          conflictResolutionPath: gl.TEST_HOST,
          sourceBranchProtected: true,
          conflictsDocsPath: '',
        },
      });
    });

    it('sets resolve button as disabled', () => {
      expect(vm.find('.js-resolve-conflicts-button').attributes('disabled')).toBe('disabled');
    });

    it('renders popover', () => {
      expect($.fn.popover).toHaveBeenCalled();
    });
  });

  describe('when source branch not protected', () => {
    beforeEach(() => {
      createComponent({
        mr: {
          canMerge: true,
          conflictResolutionPath: gl.TEST_HOST,
          sourceBranchProtected: false,
          conflictsDocsPath: '',
        },
      });
    });

    it('sets resolve button as disabled', () => {
      expect(vm.find('.js-resolve-conflicts-button').attributes('disabled')).toBe(undefined);
    });

    it('renders popover', () => {
      expect($.fn.popover).not.toHaveBeenCalled();
    });
  });
});
