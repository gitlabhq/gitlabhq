const ActionsComponent = require('~/environments/components/environment_actions');

describe('Actions Component', () => {
  preloadFixtures('static/environments/element.html.raw');

  beforeEach(() => {
    loadFixtures('static/environments/element.html.raw');
  });

  it('should render a dropdown with the provided actions', () => {
    const actionsMock = [
      {
        name: 'bar',
        play_path: 'https://gitlab.com/play',
      },
      {
        name: 'foo',
        play_path: '#',
      },
    ];

    const component = new ActionsComponent({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        actions: actionsMock,
        playIconSvg: '<svg></svg>',
      },
    });

    expect(
      component.$el.querySelectorAll('.dropdown-menu li').length,
    ).toEqual(actionsMock.length);
    expect(
      component.$el.querySelector('.dropdown-menu li a').getAttribute('href'),
    ).toEqual(actionsMock[0].play_path);
  });

  it('should render a dropdown with the provided svg', () => {
    const actionsMock = [
      {
        name: 'bar',
        play_path: 'https://gitlab.com/play',
      },
      {
        name: 'foo',
        play_path: '#',
      },
    ];

    const component = new ActionsComponent({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        actions: actionsMock,
        playIconSvg: '<svg></svg>',
      },
    });

    expect(
      component.$el.querySelector('.js-dropdown-play-icon-container').children,
    ).toContain('svg');

    expect(
      component.$el.querySelector('.js-action-play-icon-container').children,
    ).toContain('svg');
  });
});
