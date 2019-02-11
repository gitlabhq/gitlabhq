import ReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import { shallowMount, createLocalVue } from '@vue/test-utils';

const localVue = createLocalVue();

describe('ReplyPlaceholder', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(ReplyPlaceholder, {
      localVue,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('emits onClick even on button click', () => {
    const button = wrapper.find({ ref: 'button' });

    button.trigger('click');

    expect(wrapper.emitted()).toEqual({
      onClick: [[]],
    });
  });

  it('should render reply button', () => {
    const button = wrapper.find({ ref: 'button' });

    expect(button.text()).toEqual('Reply...');
  });
});
