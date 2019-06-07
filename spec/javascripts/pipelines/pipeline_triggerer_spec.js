import { mount } from '@vue/test-utils';
import pipelineTriggerer from '~/pipelines/components/pipeline_triggerer.vue';

describe('Pipelines Triggerer', () => {
  let wrapper;

  const mockData = {
    pipeline: {
      user: {
        name: 'foo',
        avatar_url: '/avatar',
        path: '/path',
      },
    },
  };

  const createComponent = () => {
    wrapper = mount(pipelineTriggerer, {
      propsData: mockData,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render a table cell', () => {
    expect(wrapper.contains('.table-section')).toBe(true);
  });

  it('should render triggerer information when triggerer is provided', () => {
    const link = wrapper.find('.js-pipeline-url-user');

    expect(link.attributes('href')).toEqual(mockData.pipeline.user.path);
    expect(link.find('.js-user-avatar-image-toolip').text()).toEqual(mockData.pipeline.user.name);
    expect(link.find('img.avatar').attributes('src')).toEqual(
      `${mockData.pipeline.user.avatar_url}?width=26`,
    );
  });

  it('should render "API" when no triggerer is provided', () => {
    wrapper.setProps({
      pipeline: {
        user: null,
      },
    });

    expect(wrapper.find('.js-pipeline-url-api').text()).toEqual('API');
  });
});
