import Vue from 'vue';
import noteAttachment from '~/notes/components/note_attachment.vue';

describe('issue note attachment', () => {
  it('should render properly', () => {
    const props = {
      attachment: {
        filename: 'dk.png',
        image: true,
        url: '/dk.png',
      },
    };

    const Component = Vue.extend(noteAttachment);
    const vm = new Component({
      propsData: props,
    }).$mount();

    expect(vm.$el.classList.contains('note-attachment')).toBeTruthy();
    expect(vm.$el.querySelector('img').src).toContain(props.attachment.url);
    expect(vm.$el.querySelector('a').href).toContain(props.attachment.url);
  });
});
