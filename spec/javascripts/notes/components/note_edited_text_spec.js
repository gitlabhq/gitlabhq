import Vue from 'vue';
import noteEditedText from '~/notes/components/note_edited_text.vue';

describe('note_edited_text', () => {
  let vm;
  let props;

  beforeEach(() => {
    const Component = Vue.extend(noteEditedText);
    props = {
      actionText: 'Edited',
      className: 'foo-bar',
      editedAt: '2017-08-04T09:52:31.062Z',
      editedBy: {
        avatar_url: 'path',
        id: 1,
        name: 'Root',
        path: '/root',
        state: 'active',
        username: 'root',
      },
    };

    vm = new Component({
      propsData: props,
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render block with provided className', () => {
    expect(vm.$el.className).toEqual(props.className);
  });

  it('should render provided actionText', () => {
    expect(vm.$el.textContent).toContain(props.actionText);
  });

  it('should render provided user information', () => {
    const authorLink = vm.$el.querySelector('.js-vue-author');

    expect(authorLink.getAttribute('href')).toEqual(props.editedBy.path);
    expect(authorLink.textContent.trim()).toEqual(props.editedBy.name);
  });
});
