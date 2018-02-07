import Vue from 'vue';
import loadingIcon from '~/vue_shared/components/loading_icon.vue';

describe('Loading Icon Component', () => {
  let LoadingIconComponent;

  beforeEach(() => {
    LoadingIconComponent = Vue.extend(loadingIcon);
  });

  it('should render a spinner font awesome icon', () => {
    const component = new LoadingIconComponent().$mount();

    expect(
      component.$el.querySelector('i').getAttribute('class'),
    ).toEqual('fa fa-spin fa-spinner fa-1x');

    expect(component.$el.tagName).toEqual('DIV');
    expect(component.$el.classList).toContain('text-center');
    expect(component.$el.classList).toContain('loading-container');
  });

  it('should render accessibility attributes', () => {
    const component = new LoadingIconComponent().$mount();

    const icon = component.$el.querySelector('i');
    expect(icon.getAttribute('aria-hidden')).toEqual('true');
    expect(icon.getAttribute('aria-label')).toEqual('Loading');
  });

  it('should render the provided label', () => {
    const component = new LoadingIconComponent({
      propsData: {
        label: 'This is a loading icon',
      },
    }).$mount();

    expect(
      component.$el.querySelector('i').getAttribute('aria-label'),
    ).toEqual('This is a loading icon');
  });

  it('should render the provided size', () => {
    const component = new LoadingIconComponent({
      propsData: {
        size: '2',
      },
    }).$mount();

    expect(
      component.$el.querySelector('i').classList.contains('fa-2x'),
    ).toEqual(true);
  });
});
