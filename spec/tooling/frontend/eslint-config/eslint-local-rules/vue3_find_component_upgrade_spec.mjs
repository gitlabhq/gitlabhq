import { RuleTester } from 'eslint';
import { vue3FindComponentUpgrade } from '../../../../../tooling/eslint-config/eslint-local-rules/vue3_find_component_upgrade.mjs';

const ruleTester = new RuleTester({
  languageOptions: {
    ecmaVersion: 2020,
    sourceType: 'module',
  },
});

ruleTester.run('vue3-find-component-upgrade', vue3FindComponentUpgrade, {
  valid: [
    // DOM-only usage of string-selector finds is fine
    { code: "wrapper.find('.foo').exists();" },
    { code: "wrapper.find('[data-testid=\"foo\"]').trigger('click');" },
    { code: "wrapper.find('.foo').setValue('bar');" },
    { code: "wrapper.findByTestId('foo').text();" },
    { code: "wrapper.findAll('.foo').at(0).trigger('click');" },
    { code: "wrapper.findAll('.foo').length;" },
    // Component selectors already return component wrappers
    { code: 'wrapper.find(MyComponent).vm;' },
    { code: 'wrapper.findComponent(MyComponent).vm;' },
    { code: "wrapper.findComponent('.foo').vm;" },
    { code: "wrapper.findComponentByTestId('foo').vm;" },
    { code: "wrapper.findAllComponents('.foo').at(0).props();" },
    // Ref selectors are a different compat concern
    { code: "wrapper.find({ ref: 'foo' }).vm;" },
    // Variables with DOM-only usage
    { code: "const el = wrapper.find('.foo'); el.trigger('click');" },
    { code: "const findFoo = () => wrapper.find('.foo'); findFoo().exists();" },
    // Multiple writes make the value ambiguous
    {
      code: "let el = wrapper.find('.foo'); el = wrapper.findComponent(Foo); el.vm;",
    },
    // Array#find with a callback is unrelated
    { code: 'items.find((item) => item.vm);' },
    // Parameterized helpers with DOM-only usage are fine
    {
      code:
        // eslint-disable-next-line no-template-curly-in-string
        'const findByTestId = (id) => wrapper.find(`[data-testid="${id}"]`); findByTestId(\'a\').exists();',
    },
  ],

  invalid: [
    {
      code: "wrapper.find('[data-testid=\"foo\"]').vm.$emit('click');",
      output: "wrapper.findComponent('[data-testid=\"foo\"]').vm.$emit('click');",
      errors: [{ messageId: 'findComponentUpgrade' }],
    },
    {
      code: "wrapper.find('.foo').props('bar');",
      output: "wrapper.findComponent('.foo').props('bar');",
      errors: [{ messageId: 'findComponentUpgrade' }],
    },
    {
      // eslint-disable-next-line no-template-curly-in-string
      code: 'wrapper.find(`[data-testid="${id}"]`).setProps({ x: 1 });',
      // eslint-disable-next-line no-template-curly-in-string
      output: 'wrapper.findComponent(`[data-testid="${id}"]`).setProps({ x: 1 });',
      errors: [{ messageId: 'findComponentUpgrade' }],
    },
    {
      code: "wrapper.find('.foo').emitted('input');",
      output: "wrapper.findComponent('.foo').emitted('input');",
      errors: [{ messageId: 'findComponentUpgrade' }],
    },
    {
      code: "wrapper.find('.foo').setData({ x: 1 });",
      output: "wrapper.findComponent('.foo').setData({ x: 1 });",
      errors: [{ messageId: 'findComponentUpgrade' }],
    },
    {
      code: "wrapper.findByTestId('foo').vm.$nextTick();",
      output: "wrapper.findComponentByTestId('foo').vm.$nextTick();",
      errors: [{ messageId: 'findComponentUpgrade' }],
    },
    {
      code: "wrapper.findAll('.foo').at(1).vm.$emit('click');",
      output: "wrapper.findAllComponents('.foo').at(1).vm.$emit('click');",
      errors: [{ messageId: 'findComponentUpgrade' }],
    },
    {
      code: "wrapper.findAllByTestId('foo').at(0).props('bar');",
      output: "wrapper.findAllComponentsByTestId('foo').at(0).props('bar');",
      errors: [{ messageId: 'findComponentUpgrade' }],
    },
    // Single-assignment const
    {
      code: "const el = wrapper.find('.foo'); el.props();",
      output: "const el = wrapper.findComponent('.foo'); el.props();",
      errors: [{ messageId: 'findComponentUpgrade' }],
    },
    // Single-write let
    {
      code: "let el; el = wrapper.find('.foo'); el.vm;",
      output: "let el; el = wrapper.findComponent('.foo'); el.vm;",
      errors: [{ messageId: 'findComponentUpgrade' }],
    },
    // Finder function idiom
    {
      code: "const findFoo = () => wrapper.find('[data-testid=\"foo\"]'); findFoo().vm.$emit('x');",
      output:
        "const findFoo = () => wrapper.findComponent('[data-testid=\"foo\"]'); findFoo().vm.$emit('x');",
      errors: [{ messageId: 'findComponentUpgrade' }],
    },
    {
      code: "const findRows = () => wrapper.findAll('.row'); findRows().at(0).emitted();",
      output:
        "const findRows = () => wrapper.findAllComponents('.row'); findRows().at(0).emitted();",
      errors: [{ messageId: 'findComponentUpgrade' }],
    },
    {
      code: "const findFoo = () => wrapper.findByTestId('foo'); findFoo().setProps({ a: 1 });",
      output:
        "const findFoo = () => wrapper.findComponentByTestId('foo'); findFoo().setProps({ a: 1 });",
      errors: [{ messageId: 'findComponentUpgrade' }],
    },
    // Component usage mixed with DOM value APIs: reported, not fixable
    {
      code: "const findInput = () => wrapper.find('.input'); findInput().vm; findInput().setValue('x');",
      output: null,
      errors: [{ messageId: 'mixedFindUpgrade' }],
    },
    {
      code: "const input = wrapper.find('.input'); input.setChecked(); input.props();",
      output: null,
      errors: [{ messageId: 'mixedFindUpgrade' }],
    },
    // Bare tag-name findAll: result set would change, not fixable
    {
      code: "wrapper.findAll('a').at(0).props('href');",
      output: null,
      errors: [{ messageId: 'bareTagFindAllUpgrade' }],
    },
    {
      code: "const links = wrapper.findAll('a'); links.at(0).vm;",
      output: null,
      errors: [{ messageId: 'bareTagFindAllUpgrade' }],
    },
    // Parameterized helper with a component-only call site: reported, not
    // fixable (other call sites may target plain elements)
    {
      code:
        // eslint-disable-next-line no-template-curly-in-string
        'const findByTestId = (id) => wrapper.find(`[data-testid="${id}"]`); findByTestId(\'a\').vm;',
      output: null,
      errors: [{ messageId: 'parameterizedFindUpgrade' }],
    },
  ],
});
