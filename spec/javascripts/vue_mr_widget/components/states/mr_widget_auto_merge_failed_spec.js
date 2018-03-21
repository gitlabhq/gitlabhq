import Vue from 'vue';
import autoMergeFailedComponent from '~/vue_merge_request_widget/components/states/mr_widget_auto_merge_failed.vue';
import eventHub from '~/vue_merge_request_widget/event_hub';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('MRWidgetAutoMergeFailed', () => {
  let vm;
  const mergeError = 'This is the merge error';

  beforeEach(() => {
    const Component = Vue.extend(autoMergeFailedComponent);
    vm = mountComponent(Component, {
      mr: { mergeError },
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders failed message', () => {
    expect(vm.$el.textContent).toContain('This merge request failed to be merged automatically');
  });

  it('renders merge error provided', () => {
    expect(vm.$el.innerText).toContain(mergeError);
  });

  it('render refresh button', () => {
    expect(vm.$el.querySelector('button').textContent.trim()).toEqual('Refresh');
  });

  it('emits event and shows loading icon when button is clicked', (done) => {
    spyOn(eventHub, '$emit');
    vm.$el.querySelector('button').click();

    expect(eventHub.$emit.calls.argsFor(0)[0]).toEqual('MRWidgetUpdateRequested');

    Vue.nextTick(() => {
      expect(vm.$el.querySelector('button').getAttribute('disabled')).toEqual('disabled');
      expect(
        vm.$el.querySelector('button i').classList,
      ).toContain('fa-spinner');
      done();
    });
  });
});
