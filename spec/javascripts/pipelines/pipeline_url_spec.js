import Vue from 'vue';
import pipelineUrlComp from '~/pipelines/components/pipeline_url';

describe('Pipeline Url Component', () => {
  let PipelineUrlComponent;

  beforeEach(() => {
    PipelineUrlComponent = Vue.extend(pipelineUrlComp);
  });

  it('should render a table cell', () => {
    const component = new PipelineUrlComponent({
      propsData: {
        pipeline: {
          id: 1,
          path: 'foo',
          flags: {},
        },
      },
    }).$mount();

    expect(component.$el.tagName).toEqual('TD');
  });

  it('should render a link the provided path and id', () => {
    const component = new PipelineUrlComponent({
      propsData: {
        pipeline: {
          id: 1,
          path: 'foo',
          flags: {},
        },
      },
    }).$mount();

    expect(component.$el.querySelector('.js-pipeline-url-link').getAttribute('href')).toEqual('foo');
    expect(component.$el.querySelector('.js-pipeline-url-link span').textContent).toEqual('#1');
  });

  it('should render user information when a user is provided', () => {
    const mockData = {
      pipeline: {
        id: 1,
        path: 'foo',
        flags: {},
        user: {
          web_url: '/',
          name: 'foo',
          avatar_url: '/',
        },
      },
    };

    const component = new PipelineUrlComponent({
      propsData: mockData,
    }).$mount();

    const image = component.$el.querySelector('.js-pipeline-url-user img');

    expect(
      component.$el.querySelector('.js-pipeline-url-user').getAttribute('href'),
    ).toEqual(mockData.pipeline.user.web_url);
    expect(image.getAttribute('title')).toEqual(mockData.pipeline.user.name);
    expect(image.getAttribute('src')).toEqual(mockData.pipeline.user.avatar_url);
  });

  it('should render "API" when no user is provided', () => {
    const component = new PipelineUrlComponent({
      propsData: {
        pipeline: {
          id: 1,
          path: 'foo',
          flags: {},
        },
      },
    }).$mount();

    expect(component.$el.querySelector('.js-pipeline-url-api').textContent).toContain('API');
  });

  it('should render latest, yaml invalid and stuck flags when provided', () => {
    const component = new PipelineUrlComponent({
      propsData: {
        pipeline: {
          id: 1,
          path: 'foo',
          flags: {
            latest: true,
            yaml_errors: true,
            stuck: true,
          },
        },
      },
    }).$mount();

    expect(component.$el.querySelector('.js-pipeline-url-lastest').textContent).toContain('latest');
    expect(component.$el.querySelector('.js-pipeline-url-yaml').textContent).toContain('yaml invalid');
    expect(component.$el.querySelector('.js-pipeline-url-stuck').textContent).toContain('stuck');
  });
});
