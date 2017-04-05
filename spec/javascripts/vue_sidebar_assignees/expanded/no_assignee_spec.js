import Vue from 'vue';
import noAssigneeComponent from '~/vue_sidebar_assignees/components/expanded/no_assignee';
import VueSpecHelper from '../../helpers/vue_spec_helper';

describe('NoAssignee', () => {
  const mockStore = {
    addCurrentUser: () => {},
  };

  const createComponent = props =>
    VueSpecHelper.createComponent(Vue, noAssigneeComponent, props);

  describe('methods', () => {
    describe('assignSelf', () => {
      it('should call addCurrentUser in store', () => {
        spyOn(mockStore, 'addCurrentUser').and.callThrough();

        const vm = createComponent({
          store: mockStore,
        });
        vm.assignSelf();

        expect(mockStore.addCurrentUser).toHaveBeenCalled();
      });
    });
  });

  describe('template', () => {
    it('should call addCurrentUser when button is clicked', () => {
      spyOn(mockStore, 'addCurrentUser').and.callThrough();

      const vm = createComponent({
        store: mockStore,
      });
      const el = vm.$el;
      const button = el.querySelector('button');
      button.click();

      expect(mockStore.addCurrentUser).toHaveBeenCalled();
    });
  });
});
