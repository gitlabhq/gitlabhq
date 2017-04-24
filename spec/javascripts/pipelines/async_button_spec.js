import Vue from 'vue';
import asyncButtonComp from '~/pipelines/components/async_button.vue';

describe('Pipelines Async Button', () => {
  let component;
  let AsyncButtonComponent;

  beforeEach(() => {
    AsyncButtonComponent = Vue.extend(asyncButtonComp);

    component = new AsyncButtonComponent({
      propsData: {
        title: 'Foo',
        icon: 'foo',
        isLoading: false,
      },
    }).$mount();
  });

  it('should render a button', () => {
    expect(component.$el.tagName).toEqual('BUTTON');
  });

  it('#iconClass computed should return the provided icon', () => {
    expect(component.iconClass).toBe('fa fa-foo');
  });

  it('should render the provided icon', () => {
    expect(component.$el.querySelector('i').getAttribute('class')).toContain('fa fa-foo');
  });

  it('should render the provided title', () => {
    expect(component.$el.getAttribute('title')).toContain('Foo');
    expect(component.$el.getAttribute('aria-label')).toContain('Foo');
  });

  it('should not render the spinner when not loading', () => {
    expect(component.$el.querySelector('.fa-spinner')).toBeNull();
  });

  it('should render the spinner when loading state changes', (done) => {
    component.isLoading = true;

    Vue.nextTick(() => {
      expect(component.$el.querySelector('.fa-spinner')).not.toBe(null);
      done();
    });
  });
});
