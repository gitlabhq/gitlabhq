import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { removeBreakLine } from 'spec/helpers/text_helper';
import ShaMismatch from '~/vue_merge_request_widget/components/states/sha_mismatch.vue';

describe('ShaMismatch', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(ShaMismatch);
    vm = mountComponent(Component);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render information message', () => {
    expect(vm.$el.querySelector('button').disabled).toEqual(true);

    expect(removeBreakLine(vm.$el.textContent).trim()).toContain(
      'The source branch HEAD has recently changed. Please reload the page and review the changes before merging',
    );
  });
});
