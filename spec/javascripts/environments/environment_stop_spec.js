import Vue from 'vue';
import stopComp from '~/environments/components/environment_stop.vue';

describe('Stop Component', () => {
  let StopComponent;
  let component;
  const stopURL = '/stop';

  beforeEach(() => {
    StopComponent = Vue.extend(stopComp);
    spyOn(window, 'confirm').and.returnValue(true);

    component = new StopComponent({
      propsData: {
        stopUrl: stopURL,
      },
    }).$mount();
  });

  describe('computed', () => {
    it('title', () => {
      expect(component.title).toEqual('Stop');
    });
  });

  it('should render a button to stop the environment', () => {
    expect(component.$el.tagName).toEqual('BUTTON');
    expect(component.$el.getAttribute('data-original-title')).toEqual('Stop');
    expect(component.$el.getAttribute('aria-label')).toEqual('Stop');
  });
});
