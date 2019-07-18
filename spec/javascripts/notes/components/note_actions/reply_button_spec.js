import Vuex from 'vuex';
import { createLocalVue, mount } from '@vue/test-utils';
import ReplyButton from '~/notes/components/note_actions/reply_button.vue';

describe('ReplyButton', () => {
  let wrapper;

  beforeEach(() => {
    const localVue = createLocalVue();

    localVue.use(Vuex);

    wrapper = mount(ReplyButton, {
      sync: false,
      localVue,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('emits startReplying on click', () => {
    const button = wrapper.find({ ref: 'button' });

    button.trigger('click');

    expect(wrapper.emitted().startReplying).toBeTruthy();
    expect(wrapper.emitted().startReplying.length).toBe(1);
  });
});
