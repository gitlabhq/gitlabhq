import Vue from 'vue';
import actionComponent from '~/pipelines/components/graph/action_component.vue';

describe('pipeline graph action component', () => {
  let component;

  beforeEach((done) => {
    const ActionComponent = Vue.extend(actionComponent);
    component = new ActionComponent({
      propsData: {
        tooltipText: 'bar',
        link: 'foo',
        actionMethod: 'post',
        actionIcon: 'cancel',
      },
    }).$mount();

    Vue.nextTick(done);
  });

  it('should render a link', () => {
    expect(component.$el.getAttribute('href')).toEqual('foo');
  });

  it('should render the provided title as a bootstrap tooltip', () => {
    expect(component.$el.getAttribute('data-original-title')).toEqual('bar');
  });

  it('should update bootstrap tooltip when title changes', (done) => {
    component.tooltipText = 'changed';

    setTimeout(() => {
      expect(component.$el.getAttribute('data-original-title')).toBe('changed');
      done();
    });
  });

  it('should render an svg', () => {
    expect(component.$el.querySelector('.ci-action-icon-wrapper')).toBeDefined();
    expect(component.$el.querySelector('svg')).toBeDefined();
  });
});
