import Vue from 'vue';
import AssigneeTitle from '~/sidebar/components/assignees/assignee_title.vue';

describe('AssigneeTitle component', () => {
  let component;
  let AssigneeTitleComponent;

  beforeEach(() => {
    AssigneeTitleComponent = Vue.extend(AssigneeTitle);
  });

  describe('assignee title', () => {
    it('renders assignee', () => {
      component = new AssigneeTitleComponent({
        propsData: {
          numberOfAssignees: 1,
          editable: false,
        },
      }).$mount();

      expect(component.$el.innerText.trim()).toEqual('Assignee');
    });

    it('renders 2 assignees', () => {
      component = new AssigneeTitleComponent({
        propsData: {
          numberOfAssignees: 2,
          editable: false,
        },
      }).$mount();

      expect(component.$el.innerText.trim()).toEqual('2 Assignees');
    });
  });

  describe('gutter toggle', () => {
    it('does not show toggle by default', () => {
      component = new AssigneeTitleComponent({
        propsData: {
          numberOfAssignees: 2,
          editable: false,
        },
      }).$mount();

      expect(component.$el.querySelector('.gutter-toggle')).toBeNull();
    });

    it('shows toggle when showToggle is true', () => {
      component = new AssigneeTitleComponent({
        propsData: {
          numberOfAssignees: 2,
          editable: false,
          showToggle: true,
        },
      }).$mount();

      expect(component.$el.querySelector('.gutter-toggle')).toEqual(jasmine.any(Object));
    });
  });

  it('does not render spinner by default', () => {
    component = new AssigneeTitleComponent({
      propsData: {
        numberOfAssignees: 0,
        editable: false,
      },
    }).$mount();

    expect(component.$el.querySelector('.fa')).toBeNull();
  });

  it('renders spinner when loading', () => {
    component = new AssigneeTitleComponent({
      propsData: {
        loading: true,
        numberOfAssignees: 0,
        editable: false,
      },
    }).$mount();

    expect(component.$el.querySelector('.fa')).not.toBeNull();
  });

  it('does not render edit link when not editable', () => {
    component = new AssigneeTitleComponent({
      propsData: {
        numberOfAssignees: 0,
        editable: false,
      },
    }).$mount();

    expect(component.$el.querySelector('.edit-link')).toBeNull();
  });

  it('renders edit link when editable', () => {
    component = new AssigneeTitleComponent({
      propsData: {
        numberOfAssignees: 0,
        editable: true,
      },
    }).$mount();

    expect(component.$el.querySelector('.edit-link')).not.toBeNull();
  });
});
