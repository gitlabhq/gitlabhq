import Vue from 'vue';
import asyncButtonComp from '~/vue_pipelines_index/components/async_button.vue';

describe('Pipelines Async Button', () => {
  let component;
  let spy;
  let AsyncButtonComponent;

  beforeEach(() => {
    AsyncButtonComponent = Vue.extend(asyncButtonComp);

    spy = jasmine.createSpy('spy').and.returnValue(Promise.resolve());

    component = new AsyncButtonComponent({
      propsData: {
        endpoint: '/foo',
        title: 'Foo',
        icon: 'fa fa-foo',
        cssClass: 'bar',
        service: {
          postAction: spy,
        },
      },
    }).$mount();
  });

  it('should render a button', () => {
    expect(component.$el.tagName).toEqual('BUTTON');
  });

  it('should render the provided icon', () => {
    expect(component.$el.querySelector('i').getAttribute('class')).toContain('fa fa-foo');
  });

  it('should render the provided title', () => {
    expect(component.$el.getAttribute('title')).toContain('Foo');
    expect(component.$el.getAttribute('aria-label')).toContain('Foo');
  });

  it('should render the provided cssClass', () => {
    expect(component.$el.getAttribute('class')).toContain('bar');
  });

  it('should call the service when it is clicked with the provided endpoint', () => {
    component.$el.click();
    expect(spy).toHaveBeenCalledWith('/foo');
  });

  it('should hide loading if request fails', () => {
    spy = jasmine.createSpy('spy').and.returnValue(Promise.reject());

    component = new AsyncButtonComponent({
      propsData: {
        endpoint: '/foo',
        title: 'Foo',
        icon: 'fa fa-foo',
        cssClass: 'bar',
        dataAttributes: {
          'data-foo': 'foo',
        },
        service: {
          postAction: spy,
        },
      },
    }).$mount();

    component.$el.click();
    expect(component.$el.querySelector('.fa-spinner')).toBe(null);
  });

  describe('With confirm dialog', () => {
    it('should call the service when confimation is positive', () => {
      spyOn(window, 'confirm').and.returnValue(true);
      spy = jasmine.createSpy('spy').and.returnValue(Promise.resolve());

      component = new AsyncButtonComponent({
        propsData: {
          endpoint: '/foo',
          title: 'Foo',
          icon: 'fa fa-foo',
          cssClass: 'bar',
          service: {
            postAction: spy,
          },
          confirmActionMessage: 'bar',
        },
      }).$mount();

      component.$el.click();
      expect(spy).toHaveBeenCalledWith('/foo');
    });
  });
});
