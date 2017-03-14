import Vue from 'vue';
import actionsComp from '~/environments/components/environment_actions';

describe('Actions Component', () => {
  let ActionsComponent;
  let actionsMock;
  let spy;
  let component;

  beforeEach(() => {
    ActionsComponent = Vue.extend(actionsComp);

    actionsMock = [
      {
        name: 'bar',
        play_path: 'https://gitlab.com/play',
      },
      {
        name: 'foo',
        play_path: '#',
      },
    ];

    spy = jasmine.createSpy('spy').and.returnValue(Promise.resolve());
    component = new ActionsComponent({
      propsData: {
        actions: actionsMock,
        service: {
          postAction: spy,
        },
      },
    }).$mount();
  });

  it('should render a dropdown with the provided actions', () => {
    expect(
      component.$el.querySelectorAll('.dropdown-menu li').length,
    ).toEqual(actionsMock.length);
  });

  it('should call the service when an action is clicked', () => {
    component.$el.querySelector('.dropdown').click();
    component.$el.querySelector('.js-manual-action-link').click();

    expect(spy).toHaveBeenCalledWith(actionsMock[0].play_path);
  });
});
