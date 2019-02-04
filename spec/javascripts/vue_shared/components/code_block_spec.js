import Vue from 'vue';
import component from '~/vue_shared/components/code_block.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Code Block', () => {
  const Component = Vue.extend(component);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  it('renders a code block with the provided code', () => {
    const code =
      "Failure/Error: is_expected.to eq(3)\n\n  expected: 3\n       got: -1\n\n  (compared using ==)\n./spec/test_spec.rb:12:in `block (4 levels) in \u003ctop (required)\u003e'";

    vm = mountComponent(Component, {
      code,
    });

    expect(vm.$el.querySelector('code').textContent).toEqual(code);
  });

  it('escapes XSS injections', () => {
    const code = 'CCC&lt;img src=x onerror=alert(document.domain)&gt;';

    vm = mountComponent(Component, {
      code,
    });

    expect(vm.$el.querySelector('code').textContent).toEqual(code);
  });
});
