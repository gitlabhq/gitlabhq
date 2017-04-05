import Vue from 'vue';
import assigneeTitleComponent from '~/vue_sidebar_assignees/components/assignee_title';
import VueSpecHelper from '../helpers/vue_spec_helper';

describe('AssigneeTitle', () => {
  const createComponent = props =>
    VueSpecHelper.createComponent(Vue, assigneeTitleComponent, props);

  describe('computed', () => {
    describe('assigneeTitle', () => {
      it('returns "Assignee" when there is only one assignee', () => {
        const vm = createComponent({
          numberOfAssignees: 1,
          editable: true,
        });
        expect(vm.assigneeTitle).toEqual('Assignee');
      });

      it('returns "Assignee" when there is only no assignee', () => {
        const vm = createComponent({
          numberOfAssignees: 0,
          editable: true,
        });
        expect(vm.assigneeTitle).toEqual('Assignee');
      });

      it('returns "2 Assignees" when there is two assignee', () => {
        const vm = createComponent({
          numberOfAssignees: 2,
          editable: false,
        });
        expect(vm.assigneeTitle).toEqual('2 Assignees');
      });
    });
  });

  describe('template', () => {
    it('should render assigneeTitle', () => {
      const vm = createComponent({
        numberOfAssignees: 100,
        editable: false,
      });
      const el = vm.$el;

      expect(el.tagName).toEqual('DIV');
      expect(el.textContent.trim()).toEqual(vm.assigneeTitle);
    });

    it('should display spinner when loading', () => {
      const el = createComponent({
        numberOfAssignees: 0,
        loading: true,
        editable: false,
      }).$el;

      const i = el.querySelector('i');
      expect(i).toBeDefined();
    });

    it('should not display spinner when not loading', () => {
      const el = createComponent({
        numberOfAssignees: 0,
        editable: true,
      }).$el;

      const i = el.querySelector('i');
      expect(i).toBeNull();
    });

    it('should display edit link when editable', () => {
      const el = createComponent({
        numberOfAssignees: 0,
        editable: true,
      }).$el;

      const editLink = el.querySelector('.edit-link');
      expect(editLink).toBeDefined();
    });

    it('should display edit link when not editable', () => {
      const el = createComponent({
        numberOfAssignees: 0,
        editable: false,
      }).$el;

      const editLink = el.querySelector('.edit-link');
      expect(editLink).toBeNull();
    });
  });
});
