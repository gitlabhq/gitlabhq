import Vue from 'vue';
import conflictsComponent from '~/vue_merge_request_widget/components/states/mr_widget_conflicts';
import mountComponent from '../../../helpers/vue_mount_component_helper';

const ConflictsComponent = Vue.extend(conflictsComponent);
const path = '/conflicts';

describe('MRWidgetConflicts', () => {
  describe('props', () => {
    it('should have props', () => {
      const { mr } = conflictsComponent.props;

      expect(mr.type instanceof Object).toBeTruthy();
      expect(mr.required).toBeTruthy();
    });
  });

  describe('template', () => {
    describe('when allowed to merge', () => {
      let vm;

      beforeEach(() => {
        vm = mountComponent(ConflictsComponent, {
          mr: {
            canMerge: true,
            conflictResolutionPath: path,
          },
        });
      });

      afterEach(() => {
        vm.$destroy();
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
      let vm;

      beforeEach(() => {
        vm = mountComponent(ConflictsComponent, {
          mr: {
            canMerge: false,
          },
        });
      });

      afterEach(() => {
        vm.$destroy();
      });

      it('should show proper message', () => {
        expect(vm.$el.textContent).toContain('ask someone with write access');
      });

      it('should not have action buttons', () => {
        expect(vm.$el.querySelector('.js-disabled-merge-button')).toBeDefined();
        expect(vm.$el.querySelector('.js-resolve-conflicts-button')).toBeNull();
        expect(vm.$el.querySelector('.js-merge-locally-button')).toBeNull();
      });
    });

    describe('when fast-forward or semi-linear merge enabled', () => {
      let vm;

      beforeEach(() => {
        vm = mountComponent(ConflictsComponent, {
          mr: {
            shouldBeRebased: true,
          },
        });
      });

      afterEach(() => {
        vm.$destroy();
      });

      it('should tell you to rebase locally', () => {
        expect(vm.$el.textContent).toContain('Fast-forward merge is not possible.');
        expect(vm.$el.textContent).toContain('To merge this request, first rebase locally');
      });
    });
  });
});
