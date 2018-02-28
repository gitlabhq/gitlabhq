import Vue from 'vue';
import navControlsComp from '~/pipelines/components/nav_controls.vue';

describe('Pipelines Nav Controls', () => {
  let NavControlsComponent;

  beforeEach(() => {
    NavControlsComponent = Vue.extend(navControlsComp);
  });

  it('should render link to create a new pipeline', () => {
    const mockData = {
      newPipelinePath: 'foo',
      hasCiEnabled: true,
      helpPagePath: 'foo',
      ciLintPath: 'foo',
      resetCachePath: 'foo',
      canCreatePipeline: true,
    };

    const component = new NavControlsComponent({
      propsData: mockData,
    }).$mount();

    expect(component.$el.querySelector('.btn-create').textContent).toContain('Run Pipeline');
    expect(component.$el.querySelector('.btn-create').getAttribute('href')).toEqual(mockData.newPipelinePath);
  });

  it('should not render link to create pipeline if no permission is provided', () => {
    const mockData = {
      newPipelinePath: 'foo',
      hasCiEnabled: true,
      helpPagePath: 'foo',
      ciLintPath: 'foo',
      resetCachePath: 'foo',
      canCreatePipeline: false,
    };

    const component = new NavControlsComponent({
      propsData: mockData,
    }).$mount();

    expect(component.$el.querySelector('.btn-create')).toEqual(null);
  });

  it('should render link for resetting runner caches', () => {
    const mockData = {
      newPipelinePath: 'foo',
      hasCiEnabled: true,
      helpPagePath: 'foo',
      ciLintPath: 'foo',
      resetCachePath: 'foo',
      canCreatePipeline: false,
    };

    const component = new NavControlsComponent({
      propsData: mockData,
    }).$mount();

    expect(component.$el.querySelectorAll('.btn-default')[0].textContent).toContain('Clear runner caches');
    expect(component.$el.querySelectorAll('.btn-default')[0].getAttribute('href')).toEqual(mockData.resetCachePath);
  });

  it('should render link for CI lint', () => {
    const mockData = {
      newPipelinePath: 'foo',
      hasCiEnabled: true,
      helpPagePath: 'foo',
      ciLintPath: 'foo',
      resetCachePath: 'foo',
      canCreatePipeline: true,
    };

    const component = new NavControlsComponent({
      propsData: mockData,
    }).$mount();

    expect(component.$el.querySelectorAll('.btn-default')[1].textContent).toContain('CI Lint');
    expect(component.$el.querySelectorAll('.btn-default')[1].getAttribute('href')).toEqual(mockData.ciLintPath);
  });

  it('should render link to help page when CI is not enabled', () => {
    const mockData = {
      newPipelinePath: 'foo',
      hasCiEnabled: false,
      helpPagePath: 'foo',
      ciLintPath: 'foo',
      resetCachePath: 'foo',
      canCreatePipeline: true,
    };

    const component = new NavControlsComponent({
      propsData: mockData,
    }).$mount();

    expect(component.$el.querySelector('.btn-info').textContent).toContain('Get started with Pipelines');
    expect(component.$el.querySelector('.btn-info').getAttribute('href')).toEqual(mockData.helpPagePath);
  });

  it('should not render link to help page when CI is enabled', () => {
    const mockData = {
      newPipelinePath: 'foo',
      hasCiEnabled: true,
      helpPagePath: 'foo',
      ciLintPath: 'foo',
      resetCachePath: 'foo',
      canCreatePipeline: true,
    };

    const component = new NavControlsComponent({
      propsData: mockData,
    }).$mount();

    expect(component.$el.querySelector('.btn-info')).toEqual(null);
  });
});
