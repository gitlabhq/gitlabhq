import Vuex from 'vuex';
import { createLocalVue, mount } from '@vue/test-utils';
import ReplyButton from '~/notes/components/note_actions/reply_button.vue';

describe('ReplyButton', () => {
  const noteId = 'dummy-note-id';

  let wrapper;
  let convertToDiscussion;

  beforeEach(() => {
    const localVue = createLocalVue();
    convertToDiscussion = jasmine.createSpy('convertToDiscussion');

    localVue.use(Vuex);
    const store = new Vuex.Store({
      actions: {
        convertToDiscussion,
      },
    });

    wrapper = mount(ReplyButton, {
      propsData: {
        noteId,
      },
      store,
      sync: false,
      localVue,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('dispatches convertToDiscussion with note ID on click', () => {
    const button = wrapper.find({ ref: 'button' });

    button.trigger('click');

    expect(convertToDiscussion).toHaveBeenCalledTimes(1);
    const [, payload] = convertToDiscussion.calls.argsFor(0);

    expect(payload).toBe(noteId);
  });
});
