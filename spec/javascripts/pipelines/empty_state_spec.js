import Vue from 'vue';
import emptyStateComp from '~/pipelines/components/empty_state.vue';

describe('Pipelines Empty State', () => {
  let component;
  let EmptyStateComponent;

  beforeEach(() => {
    EmptyStateComponent = Vue.extend(emptyStateComp);

    component = new EmptyStateComponent({
      propsData: {
        helpPagePath: 'foo',
        emptyStateSvgPath: 'foo',
      },
    }).$mount();
  });

  it('should render empty state SVG', () => {
    expect(component.$el.querySelector('.svg-content svg')).toBeDefined();
  });

  it('should render emtpy state information', () => {
    expect(component.$el.querySelector('h4').textContent).toContain('Build with confidence');

    expect(
      component.$el.querySelector('p').textContent,
    ).toContain('Continous Integration can help catch bugs by running your tests automatically');

    expect(
      component.$el.querySelector('p').textContent,
    ).toContain('Continuous Deployment can help you deliver code to your product environment');
  });

  it('should render a link with provided help path', () => {
    expect(component.$el.querySelector('.btn-info').getAttribute('href')).toEqual('foo');
    expect(component.$el.querySelector('.btn-info').textContent).toContain('Get started with Pipelines');
  });
});
