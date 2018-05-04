import Vue from 'vue';
import conflictsComponent from '~/vue_merge_request_widget/components/states/mr_widget_conflicts.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { removeBreakLine } from 'spec/helpers/vue_component_helper';

describe('MRWidgetConflicts', () => {
  let Component;
  let vm;
  const path = '/conflicts';

  beforeEach(() => {
    Component = Vue.extend(conflictsComponent);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('when allowed to merge', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        mr: {
          canMerge: true,
          conflictResolutionPath: path,
        },
      });
    });

    it('should tell you about conflicts without bothering other people', () => {
      expect(vm.$el.textContent).toContain('There are merge conflicts');
      expect(vm.$el.textContent).not.toContain('ask someone with write access');
    });

    it('should allow you to resolve the conflicts', () => {
      const resolveButton = vm.$el.querySelector('.js-resolve-conflicts-button');

      expect(resolveButton.textContent).toContain('Resolve conflicts');
      expect(resolveButton.getAttribute('href')).toEqual(path);
    });

    it('should have merge buttons', () => {
      const mergeButton = vm.$el.querySelector('.js-disabled-merge-button');
      const mergeLocallyButton = vm.$el.querySelector('.js-merge-locally-button');

      expect(mergeButton.textContent).toContain('Merge');
      expect(mergeButton.disabled).toBeTruthy();
      expect(mergeButton.classList.contains('btn-success')).toEqual(true);
      expect(mergeLocallyButton.textContent).toContain('Merge locally');
    });
  });

  describe('when user does not have permission to merge', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        mr: {
          canMerge: false,
        },
      });
    });

    it('should show proper message', () => {
      expect(vm.$el.textContent.trim().replace(/\s\s+/g, ' ')).toContain('ask someone with write access');
    });

    it('should not have action buttons', () => {
      expect(vm.$el.querySelector('.js-disabled-merge-button')).toBeDefined();
      expect(vm.$el.querySelector('.js-resolve-conflicts-button')).toBeNull();
      expect(vm.$el.querySelector('.js-merge-locally-button')).toBeNull();
    });
  });

  describe('when fast-forward or semi-linear merge enabled', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        mr: {
          shouldBeRebased: true,
        },
      });
    });

    it('should tell you to rebase locally', () => {
      expect(
        removeBreakLine(vm.$el.textContent).trim(),
      ).toContain('Fast-forward merge is not possible. To merge this request, first rebase locally.');
    });
  });
});
