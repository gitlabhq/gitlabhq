import Vue from 'vue';
import issueNoteSignedOut from '~/notes/components/issue_note_signed_out_widget.vue';
import store from '~/notes/stores';
import { notesDataMock } from '../mock_data';

describe('issue_note_signed_out_widget component', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(issueNoteSignedOut);
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
