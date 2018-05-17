import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import actionComponent from '~/pipelines/components/graph/action_component.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('pipeline graph action component', () => {
  let component;
  let mock;

  beforeEach(done => {
    const ActionComponent = Vue.extend(actionComponent);
    mock = new MockAdapter(axios);

    mock.onPost('foo.json').reply(200);

    component = mountComponent(ActionComponent, {
      tooltipText: 'bar',
      link: 'foo',
      actionIcon: 'cancel',
    });

    Vue.nextTick(done);
  });

  afterEach(() => {
    mock.restore();
    component.$destroy();
  });

<<<<<<< HEAD
=======
  it('should emit an event with the provided link', () => {
    eventHub.$on('postAction', link => {
      expect(link).toEqual('foo');
    });
  });

>>>>>>> f67fa26c271... Undo unrelated changes from b1fa486b74875df8cddb4aab8f6d31c036b38137
  it('should render the provided title as a bootstrap tooltip', () => {
    expect(component.$el.getAttribute('data-original-title')).toEqual('bar');
  });

  it('should update bootstrap tooltip when title changes', done => {
    component.tooltipText = 'changed';

    component.$nextTick()
    .then(() => {
      expect(component.$el.getAttribute('data-original-title')).toBe('changed');
    })
    .then(done)
    .catch(done.fail);
  });

  it('should render an svg', () => {
    expect(component.$el.querySelector('.ci-action-icon-wrapper')).toBeDefined();
    expect(component.$el.querySelector('svg')).toBeDefined();
  });

  describe('on click', () => {
    it('emits `pipelineActionRequestComplete` after a successfull request', done => {
      spyOn(component, '$emit');

      component.$el.click();

      component.$nextTick()
        .then(() => {
          expect(component.$emit).toHaveBeenCalledWith('pipelineActionRequestComplete');
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
