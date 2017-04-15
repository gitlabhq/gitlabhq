import Vue from 'vue';
import pipelinesActionsComp from '~/vue_pipelines_index/components/pipelines_actions';

describe('Pipelines Actions dropdown', () => {
  let component;
  let spy;
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

    spy = jasmine.createSpy('spy').and.returnValue(Promise.resolve());

    component = new ActionsComponent({
      propsData: {
        actions,
        service: {
          postAction: spy,
        },
      },
    }).$mount();
  });

  it('should render a dropdown with the provided actions', () => {
    expect(
      component.$el.querySelectorAll('.dropdown-menu li').length,
    ).toEqual(actions.length);
  });

  it('should call the service when an action is clicked', () => {
    component.$el.querySelector('.js-pipeline-dropdown-manual-actions').click();
    component.$el.querySelector('.js-pipeline-action-link').click();

    expect(spy).toHaveBeenCalledWith(actions[0].path);
  });

  it('should hide loading if request fails', () => {
    spy = jasmine.createSpy('spy').and.returnValue(Promise.reject());

    component = new ActionsComponent({
      propsData: {
        actions,
        service: {
          postAction: spy,
        },
      },
    }).$mount();

    component.$el.querySelector('.js-pipeline-dropdown-manual-actions').click();
    component.$el.querySelector('.js-pipeline-action-link').click();

    expect(component.$el.querySelector('.fa-spinner')).toEqual(null);
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
