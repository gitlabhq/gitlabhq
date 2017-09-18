import Vue from 'vue';
import conflictsComponent from '~/vue_merge_request_widget/components/states/mr_widget_conflicts';

const path = '/conflicts';
const createComponent = (customConfig = {}) => {
  const Component = Vue.extend(conflictsComponent);

  const config = Object.assign({
    mr: {},
  }, customConfig);

  return new Component({
    el: document.createElement('div'),
    propsData: config,
  });
};

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
        vm = createComponent({
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
        const resolveButton = vm.$refs.resolveConflictsButton;

        expect(resolveButton.textContent).toContain('Resolve conflicts');
        expect(resolveButton.getAttribute('href')).toEqual(path);
      });

      it('should have merge buttons', () => {
        const mergeButton = vm.$refs.statusIcon.$refs.mergeButton;
        const mergeLocallyButton = vm.$refs.mergeLocallyButton;

        expect(mergeButton.textContent).toContain('Merge');
        expect(mergeButton.disabled).toBeTruthy();
        expect(mergeButton.classList.contains('btn-success')).toBeTruthy();
        expect(mergeLocallyButton.textContent).toContain('Merge locally');
      });
    });

    describe('when user does not have permission to merge', () => {
      let vm;

      beforeEach(() => {
        vm = createComponent({
          mr: {
            canMerge: false,
          },
        });
      });

      it('should show proper message', () => {
        expect(vm.$el.textContent).toContain('ask someone with write access');
      });

      it('should not have action buttons', () => {
        expect(vm.$refs.statusIcon.$refs.mergeButton).toBeDefined();
        expect(vm.$refs.resolveConflictsButton).toBeUndefined();
        expect(vm.$refs.mergeLocallyButton).toBeUndefined();
      });
    });

    describe('when fast-forward merge enabled', () => {
      let vm;

      beforeEach(() => {
        vm = createComponent({
          mr: {
            ffOnlyEnabled: true,
          },
        });
      });

      it('should tell you to rebase locally', () => {
        expect(vm.$el.textContent).toContain('Fast-forward merge is not possible.');
        expect(vm.$el.textContent).toContain('To merge this request, first rebase locally');
      });
    });
  });
});
