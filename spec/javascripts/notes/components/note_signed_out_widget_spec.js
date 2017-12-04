import Vue from 'vue';
import noteSignedOut from '~/notes/components/note_signed_out_widget.vue';
import store from '~/notes/stores';
import { notesDataMock } from '../mock_data';

describe('note_signed_out_widget component', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(noteSignedOut);
    store.dispatch('setNotesData', notesDataMock);

    vm = new Component({
      store,
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render sign in link provided in the store', () => {
    expect(
      vm.$el.querySelector(`a[href="${notesDataMock.newSessionPath}"]`).textContent,
    ).toEqual('sign in');
  });

  it('should render register link provided in the store', () => {
    expect(
      vm.$el.querySelector(`a[href="${notesDataMock.registerPath}"]`).textContent,
    ).toEqual('register');
  });

  it('should render information text', () => {
    expect(vm.$el.textContent.replace(/\s+/g, ' ').trim()).toEqual('Please register or sign in to reply');
  });
});
