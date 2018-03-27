import Vue from 'vue';
import asyncButtonComp from '~/pipelines/components/async_button.vue';
import eventHub from '~/pipelines/event_hub';

describe('Pipelines Async Button', () => {
  let component;
  let AsyncButtonComponent;

  beforeEach(() => {
    AsyncButtonComponent = Vue.extend(asyncButtonComp);

    component = new AsyncButtonComponent({
      propsData: {
        endpoint: '/foo',
        title: 'Foo',
        icon: 'repeat',
        cssClass: 'bar',
        pipelineId: 123,
        type: 'explode',
      },
    }).$mount();
  });

  it('should render a button', () => {
    expect(component.$el.tagName).toEqual('BUTTON');
  });

  it('should render svg icon', () => {
    expect(component.$el.querySelector('svg')).not.toBeNull();
  });

  it('should render the provided title', () => {
    expect(component.$el.getAttribute('data-original-title')).toContain('Foo');
    expect(component.$el.getAttribute('aria-label')).toContain('Foo');
  });

  it('should render the provided cssClass', () => {
    expect(component.$el.getAttribute('class')).toContain('bar');
  });

  describe('With confirm dialog', () => {
    it('should call the service when confimation is positive', () => {
      eventHub.$on('openConfirmationModal', (data) => {
        expect(data.pipelineId).toEqual(123);
        expect(data.type).toEqual('explode');
      });

      component = new AsyncButtonComponent({
        propsData: {
          endpoint: '/foo',
          title: 'Foo',
          icon: 'fa fa-foo',
          cssClass: 'bar',
          pipelineId: 123,
          type: 'explode',
        },
      }).$mount();

      component.$el.click();
    });
  });
});
