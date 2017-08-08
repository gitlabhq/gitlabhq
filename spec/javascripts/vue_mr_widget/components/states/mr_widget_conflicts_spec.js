import Vue from 'vue';
import conflictsComponent from '~/vue_merge_request_widget/components/states/mr_widget_conflicts';

const path = '/conflicts';
const createComponent = () => {
  const Component = Vue.extend(conflictsComponent);

  return new Component({
    el: document.createElement('div'),
    propsData: {
      mr: {
        canMerge: true,
        conflictResolutionPath: path,
      },
    },
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
    it('should have correct elements', () => {
      const el = createComponent().$el;
      const resolveButton = el.querySelector('.js-resolve-conflicts-button');
      const mergeButton = el.querySelector('.mr-widget-body .btn');
      const mergeLocallyButton = el.querySelector('.js-merge-locally-button');

      expect(el.textContent).toContain('There are merge conflicts');
      expect(el.textContent).not.toContain('ask someone with write access');
      expect(el.querySelector('.btn-success').disabled).toBeTruthy();
      expect(resolveButton.textContent).toContain('Resolve conflicts');
      expect(resolveButton.getAttribute('href')).toEqual(path);
      expect(mergeButton.textContent).toContain('Merge');
      expect(mergeLocallyButton.textContent).toContain('Merge locally');
    });

    describe('when user does not have permission to merge', () => {
      let vm;

      beforeEach(() => {
        vm = createComponent();
        vm.mr.canMerge = false;
      });

      it('should show proper message', (done) => {
        Vue.nextTick(() => {
          expect(vm.$el.textContent).toContain('ask someone with write access');
          done();
        });
      });

      it('should not have action buttons', (done) => {
        Vue.nextTick(() => {
          expect(vm.$el.querySelectorAll('.btn').length).toBe(1);
          expect(vm.$el.querySelector('.js-resolve-conflicts-button')).toEqual(null);
          expect(vm.$el.querySelector('.js-merge-locally-button')).toEqual(null);
          done();
        });
      });
    });
  });
});
