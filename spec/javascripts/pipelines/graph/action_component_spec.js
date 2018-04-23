import Vue from 'vue';
import actionComponent from '~/pipelines/components/graph/action_component.vue';
import eventHub from '~/pipelines/event_hub';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('pipeline graph action component', () => {
  let component;

  beforeEach(done => {
    const ActionComponent = Vue.extend(actionComponent);
    component = mountComponent(ActionComponent, {
      tooltipText: 'bar',
      link: 'foo',
      actionIcon: 'cancel',
    });

    Vue.nextTick(done);
  });

  afterEach(() => {
    component.$destroy();
  });

  it('should emit an event with the provided link', () => {
    eventHub.$on('graphAction', link => {
      expect(link).toEqual('foo');
    });
  });

  it('should render the provided title as a bootstrap tooltip', () => {
    expect(component.$el.getAttribute('data-original-title')).toEqual('bar');
  });

  it('should update bootstrap tooltip when title changes', done => {
    component.tooltipText = 'changed';

    setTimeout(() => {
      expect(component.$el.getAttribute('data-original-title')).toBe('changed');
      done();
    });
  });

  it('should render an svg', () => {
    expect(component.$el.querySelector('.ci-action-icon-wrapper')).toBeDefined();
    expect(component.$el.querySelector('svg')).toBeDefined();
  });

  it('disables the button when clicked', done => {
    component.$el.click();

    component.$nextTick(() => {
      expect(component.$el.getAttribute('disabled')).toEqual('disabled');
      done();
    });
  });

  it('re-enabled the button when `requestFinishedFor` matches `linkRequested`', done => {
    component.$el.click();

    component
      .$nextTick()
      .then(() => {
        expect(component.$el.getAttribute('disabled')).toEqual('disabled');
        component.requestFinishedFor = 'foo';
      })
      .then(() => {
        expect(component.$el.getAttribute('disabled')).toBeNull();
      })
      .then(done)
      .catch(done.fail);
  });

  it('does not re-enable the button when `requestFinishedFor` does not matches `linkRequested`', done => {
    component.$el.click();

    component
      .$nextTick()
      .then(() => {
        expect(component.$el.getAttribute('disabled')).toEqual('disabled');
        component.requestFinishedFor = 'bar';
      })
      .then(() => {
        expect(component.$el.getAttribute('disabled')).toEqual('disabled');
      })
      .then(done)
      .catch(done.fail);
  });
});
