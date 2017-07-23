import Vue from 'vue';
import actionsComp from '~/environments/components/environment_actions.vue';

describe('Actions Component', () => {
  let ActionsComponent;
  let actionsMock;
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
      {
        name: 'foo bar',
        play_path: 'url',
        playable: false,
      },
    ];

    component = new ActionsComponent({
      propsData: {
        actions: actionsMock,
      },
    }).$mount();
  });

  describe('computed', () => {
    it('title', () => {
      expect(component.title).toEqual('Deploy to...');
    });
  });

  it('should render a dropdown button with icon and title attribute', () => {
    expect(component.$el.querySelector('.fa-caret-down')).toBeDefined();
    expect(component.$el.querySelector('.dropdown-new').getAttribute('data-original-title')).toEqual('Deploy to...');
    expect(component.$el.querySelector('.dropdown-new').getAttribute('aria-label')).toEqual('Deploy to...');
  });

  it('should render a dropdown with the provided list of actions', () => {
    expect(
      component.$el.querySelectorAll('.dropdown-menu li').length,
    ).toEqual(actionsMock.length);
  });

  it('should render a disabled action when it\'s not playable', () => {
    expect(
      component.$el.querySelector('.dropdown-menu li:last-child button').getAttribute('disabled'),
    ).toEqual('disabled');

    expect(
      component.$el.querySelector('.dropdown-menu li:last-child button').classList.contains('disabled'),
    ).toEqual(true);
  });
});
