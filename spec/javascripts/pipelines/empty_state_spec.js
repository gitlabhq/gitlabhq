import Vue from 'vue';
import emptyStateComp from '~/pipelines/components/empty_state.vue';
import mountComponent from '../helpers/vue_mount_component_helper';

describe('Pipelines Empty State', () => {
  let component;
  let EmptyStateComponent;

  beforeEach(() => {
    EmptyStateComponent = Vue.extend(emptyStateComp);

    component = mountComponent(EmptyStateComponent, {
      helpPagePath: 'foo',
      emptyStateSvgPath: 'foo',
      canSetCi: true,
    });
  });

  afterEach(() => {
    component.$destroy();
  });

  it('should render empty state SVG', () => {
    expect(component.$el.querySelector('.svg-content svg')).toBeDefined();
  });

  it('should render emtpy state information', () => {
    expect(component.$el.querySelector('h4').textContent).toContain('Build with confidence');

    expect(
      component.$el.querySelector('p').innerHTML.trim().replace(/\n+\s+/m, ' ').replace(/\s\s+/g, ' '),
    ).toContain('Continous Integration can help catch bugs by running your tests automatically,');

    expect(
      component.$el.querySelector('p').innerHTML.trim().replace(/\n+\s+/m, ' ').replace(/\s\s+/g, ' '),
    ).toContain('while Continuous Deployment can help you deliver code to your product environment');
  });

  it('should render a link with provided help path', () => {
    expect(component.$el.querySelector('.js-get-started-pipelines').getAttribute('href')).toEqual('foo');
    expect(component.$el.querySelector('.js-get-started-pipelines').textContent).toContain('Get started with Pipelines');
  });
});
