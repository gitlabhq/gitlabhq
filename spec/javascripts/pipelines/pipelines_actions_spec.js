import Vue from 'vue';
import pipelinesActionsComp from '~/pipelines/components/pipelines_actions.vue';

describe('Pipelines Actions dropdown', () => {
  let component;
  let actions;
  let ActionsComponent;

  beforeEach(() => {
    ActionsComponent = Vue.extend(pipelinesActionsComp);

    actions = [
      {
        name: 'stop_review',
        path: '/root/review-app/builds/1893/play',
      },
      {
        name: 'foo',
        path: '#',
        playable: false,
      },
    ];

    component = new ActionsComponent({
      propsData: {
        actions,
      },
    }).$mount();
  });

  it('should render a dropdown with the provided actions', () => {
    expect(
      component.$el.querySelectorAll('.dropdown-menu li').length,
    ).toEqual(actions.length);
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
