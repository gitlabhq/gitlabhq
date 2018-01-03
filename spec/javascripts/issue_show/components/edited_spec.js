import Vue from 'vue';
import edited from '~/issue_show/components/edited.vue';

function formatText(text) {
  return text.trim().replace(/\s\s+/g, ' ');
}

describe('edited', () => {
  const EditedComponent = Vue.extend(edited);

  it('should render an edited at+by string', () => {
    const editedComponent = new EditedComponent({
      propsData: {
        updatedAt: '2017-05-15T12:31:04.428Z',
        updatedByName: 'Some User',
        updatedByPath: '/some_user',
      },
    }).$mount();

    expect(formatText(editedComponent.$el.innerText)).toMatch(/Edited[\s\S]+?by Some User/);
    expect(editedComponent.$el.querySelector('.author_link').href).toMatch(/\/some_user$/);
    expect(editedComponent.$el.querySelector('time')).toBeTruthy();
  });

  it('if no updatedAt is provided, no time element will be rendered', () => {
    const editedComponent = new EditedComponent({
      propsData: {
        updatedByName: 'Some User',
        updatedByPath: '/some_user',
      },
    }).$mount();

    expect(formatText(editedComponent.$el.innerText)).toMatch(/Edited by Some User/);
    expect(editedComponent.$el.querySelector('.author_link').href).toMatch(/\/some_user$/);
    expect(editedComponent.$el.querySelector('time')).toBeFalsy();
  });

  it('if no updatedByName and updatedByPath is provided, no user element will be rendered', () => {
    const editedComponent = new EditedComponent({
      propsData: {
        updatedAt: '2017-05-15T12:31:04.428Z',
      },
    }).$mount();

    expect(formatText(editedComponent.$el.innerText)).not.toMatch(/by Some User/);
    expect(editedComponent.$el.querySelector('.author_link')).toBeFalsy();
    expect(editedComponent.$el.querySelector('time')).toBeTruthy();
  });

  it('renders time ago tooltip at the bottom', () => {
    const editedComponent = new EditedComponent({
      propsData: {
        updatedAt: '2017-05-15T12:31:04.428Z',
      },
    }).$mount();

    expect(editedComponent.$el.querySelector('time').dataset.placement).toEqual('bottom');
  });
});
