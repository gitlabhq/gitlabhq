import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import TokenedInput from '~/ide/components/shared/tokened_input.vue';

const TEST_PLACEHOLDER = 'Searching in test';
const TEST_TOKENS = [
  { label: 'lorem', id: 1 },
  { label: 'ipsum', id: 2 },
  { label: 'dolar', id: 3 },
];
const TEST_VALUE = 'lorem';

function getTokenElements(vm) {
  return Array.from(vm.$el.querySelectorAll('.filtered-search-token button'));
}

function createBackspaceEvent() {
  const e = new Event('keyup');
  e.keyCode = 8;
  e.which = e.keyCode;
  e.altKey = false;
  e.ctrlKey = true;
  e.shiftKey = false;
  e.metaKey = false;
  return e;
}

describe('IDE shared/TokenedInput', () => {
  const Component = Vue.extend(TokenedInput);
  let vm;

  beforeEach(() => {
    vm = mountComponent(Component, {
      tokens: TEST_TOKENS,
      placeholder: TEST_PLACEHOLDER,
      value: TEST_VALUE,
    });

    spyOn(vm, '$emit');
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders tokens', () => {
    const renderedTokens = getTokenElements(vm).map(x => x.textContent.trim());

    expect(renderedTokens).toEqual(TEST_TOKENS.map(x => x.label));
  });

  it('renders input', () => {
    expect(vm.$refs.input).toBeTruthy();
    expect(vm.$refs.input).toHaveValue(TEST_VALUE);
  });

  it('renders placeholder, when tokens are empty', done => {
    vm.tokens = [];

    vm.$nextTick()
      .then(() => {
        expect(vm.$refs.input).toHaveAttr('placeholder', TEST_PLACEHOLDER);
      })
      .then(done)
      .catch(done.fail);
  });

  it('triggers "removeToken" on token click', () => {
    getTokenElements(vm)[0].click();

    expect(vm.$emit).toHaveBeenCalledWith('removeToken', TEST_TOKENS[0]);
  });

  it('when input triggers backspace event, it calls "onBackspace"', () => {
    spyOn(vm, 'onBackspace');

    vm.$refs.input.dispatchEvent(createBackspaceEvent());
    vm.$refs.input.dispatchEvent(createBackspaceEvent());

    expect(vm.onBackspace).toHaveBeenCalledTimes(2);
  });

  it('triggers "removeToken" on backspaces when value is empty', () => {
    vm.value = '';

    vm.onBackspace();

    expect(vm.$emit).not.toHaveBeenCalled();
    expect(vm.backspaceCount).toEqual(1);

    vm.onBackspace();

    expect(vm.$emit).toHaveBeenCalledWith('removeToken', TEST_TOKENS[TEST_TOKENS.length - 1]);
    expect(vm.backspaceCount).toEqual(0);
  });

  it('does not trigger "removeToken" on backspaces when value is not empty', () => {
    vm.onBackspace();
    vm.onBackspace();

    expect(vm.backspaceCount).toEqual(0);
    expect(vm.$emit).not.toHaveBeenCalled();
  });

  it('does not trigger "removeToken" on backspaces when tokens are empty', () => {
    vm.tokens = [];

    vm.onBackspace();
    vm.onBackspace();

    expect(vm.backspaceCount).toEqual(0);
    expect(vm.$emit).not.toHaveBeenCalled();
  });

  it('triggers "focus" on input focus', () => {
    vm.$refs.input.dispatchEvent(new Event('focus'));

    expect(vm.$emit).toHaveBeenCalledWith('focus');
  });

  it('triggers "blur" on input blur', () => {
    vm.$refs.input.dispatchEvent(new Event('blur'));

    expect(vm.$emit).toHaveBeenCalledWith('blur');
  });

  it('triggers "input" with value on input change', () => {
    vm.$refs.input.value = 'something-else';
    vm.$refs.input.dispatchEvent(new Event('input'));

    expect(vm.$emit).toHaveBeenCalledWith('input', 'something-else');
  });
});
