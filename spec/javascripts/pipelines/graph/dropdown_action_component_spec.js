import Vue from 'vue';
import dropdownActionComponent from '~/pipelines/components/graph/dropdown_action_component.vue';

describe('action component', () => {
  let component;

  beforeEach((done) => {
    const DropdownActionComponent = Vue.extend(dropdownActionComponent);
    component = new DropdownActionComponent({
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

  it('should render an svg', () => {
    expect(component.$el.querySelector('svg')).toBeDefined();
  });
});
