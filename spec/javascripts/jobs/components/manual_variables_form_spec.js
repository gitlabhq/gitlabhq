import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import Form from '~/jobs/components/manual_variables_form.vue';

const localVue = createLocalVue();

describe('Manual Variables Form', () => {
  let wrapper;

  const requiredProps = {
    action: {
      path: '/play',
      method: 'post',
      button_title: 'Trigger this manual action',
    },
    variablesSettingsUrl: '/settings',
  };

  const factory = (props = {}) => {
    wrapper = shallowMount(localVue.extend(Form), {
      propsData: props,
      localVue,
      sync: false,
    });
  };

  beforeEach(() => {
    factory(requiredProps);
  });

  afterEach(done => {
    // The component has a `nextTick` callback after some events so we need
    // to wait for those to finish before destroying.
    setImmediate(() => {
      wrapper.destroy();
      wrapper = null;

      done();
    });
  });

  it('renders empty form with correct placeholders', () => {
    expect(wrapper.find({ ref: 'inputKey' }).attributes('placeholder')).toBe('Input variable key');
    expect(wrapper.find({ ref: 'inputSecretValue' }).attributes('placeholder')).toBe(
      'Input variable value',
    );
  });

  it('renders help text with provided link', () => {
    expect(wrapper.find('p').text()).toBe(
      'Specify variable values to be used in this run. The values specified in CI/CD settings will be used as default',
    );

    expect(wrapper.find('a').attributes('href')).toBe(requiredProps.variablesSettingsUrl);
  });

  describe('when adding a new variable', () => {
    it('creates a new variable when user types a new key and resets the form', done => {
      wrapper.vm
        .$nextTick()
        .then(() => wrapper.find({ ref: 'inputKey' }).setValue('new key'))
        .then(() => {
          expect(wrapper.vm.variables.length).toBe(1);
          expect(wrapper.vm.variables[0].key).toBe('new key');
          expect(wrapper.find({ ref: 'inputKey' }).attributes('value')).toBe(undefined);
        })
        .then(done)
        .catch(done.fail);
    });

    it('creates a new variable when user types a new value and resets the form', done => {
      wrapper.vm
        .$nextTick()
        .then(() => wrapper.find({ ref: 'inputSecretValue' }).setValue('new value'))
        .then(() => {
          expect(wrapper.vm.variables.length).toBe(1);
          expect(wrapper.vm.variables[0].secret_value).toBe('new value');
          expect(wrapper.find({ ref: 'inputSecretValue' }).attributes('value')).toBe(undefined);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('when deleting a variable', () => {
    beforeEach(done => {
      wrapper.vm.variables = [
        {
          key: 'new key',
          secret_value: 'value',
          id: '1',
        },
      ];

      wrapper.vm.$nextTick(done);
    });

    it('removes the variable row', () => {
      wrapper.find(GlButton).vm.$emit('click');

      expect(wrapper.vm.variables.length).toBe(0);
    });
  });
});
