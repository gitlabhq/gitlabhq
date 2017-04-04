import Vue from 'vue';
import stopComp from '~/environments/components/environment_stop';

describe('Stop Component', () => {
  let StopComponent;
  let component;
  let spy;
  const stopURL = '/stop';

  beforeEach(() => {
    StopComponent = Vue.extend(stopComp);
    spy = jasmine.createSpy('spy').and.returnValue(Promise.resolve());
    spyOn(window, 'confirm').and.returnValue(true);

    component = new StopComponent({
      propsData: {
        stopUrl: stopURL,
        service: {
          postAction: spy,
        },
      },
    }).$mount();
  });

  it('should render a button to stop the environment', () => {
    expect(component.$el.tagName).toEqual('BUTTON');
    expect(component.$el.getAttribute('title')).toEqual('Stop');
  });

  it('should call the service when an action is clicked', () => {
    component.$el.click();
    expect(spy).toHaveBeenCalled();
  });
});
