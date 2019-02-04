import Vue from 'vue';
import issueSystemNote from '~/vue_shared/components/notes/system_note.vue';
import createStore from '~/notes/stores';

describe('system note component', () => {
  let vm;
  let props;

  beforeEach(() => {
    props = {
      note: {
        id: '1424',
        author: {
          id: 1,
          name: 'Root',
          username: 'root',
          state: 'active',
          avatar_url: 'path',
          path: '/root',
        },
        note_html: '<p dir="auto">closed</p>',
        system_note_icon_name: 'status_closed',
        created_at: '2017-08-02T10:51:58.559Z',
      },
    };

    const store = createStore();
    store.dispatch('setTargetNoteHash', `note_${props.note.id}`);

    const Component = Vue.extend(issueSystemNote);
    vm = new Component({
      store,
      propsData: props,
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render a list item with correct id', () => {
    expect(vm.$el.getAttribute('id')).toEqual(`note_${props.note.id}`);
  });

  it('should render target class is note is target note', () => {
    expect(vm.$el.classList).toContain('target');
  });

  it('should render svg icon', () => {
    expect(vm.$el.querySelector('.timeline-icon svg')).toBeDefined();
  });

  // Redcarpet Markdown renderer wraps text in `<p>` tags
  // we need to strip them because they break layout of commit lists in system notes:
  // https://gitlab.com/gitlab-org/gitlab-ce/uploads/b07a10670919254f0220d3ff5c1aa110/jqzI.png
  it('removes wrapping paragraph from note HTML', () => {
    expect(vm.$el.querySelector('.system-note-message').innerHTML).toEqual('<span>closed</span>');
  });
});
