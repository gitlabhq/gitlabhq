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

  it('should render the provided title as a bootstrap tooltip', () => {
    expect(component.$el.getAttribute('data-original-title')).toEqual('bar');
  });

  it('should update bootstrap tooltip when title changes', done => {
    component.tooltipText = 'changed';

    component
      .$nextTick()
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
    it('emits `pipelineActionRequestComplete` after a successful request', done => {
      spyOn(component, '$emit');

      component.$el.click();

      setTimeout(() => {
        component
          .$nextTick()
          .then(() => {
            expect(component.$emit).toHaveBeenCalledWith('pipelineActionRequestComplete');
          })
          .catch(done.fail);

        done();
      }, 0);
    });

    it('renders a loading icon while waiting for request', done => {
      component.$el.click();

      component.$nextTick(() => {
        expect(component.$el.querySelector('.js-action-icon-loading')).not.toBeNull();
        setTimeout(() => {
          done();
        });
      });
    });
  });
});
