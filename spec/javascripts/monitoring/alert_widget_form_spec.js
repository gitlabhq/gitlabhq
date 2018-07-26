import Vue from 'vue';
import AlertWidgetForm from 'ee/monitoring/components/alert_widget_form.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('AlertWidgetForm', () => {
  let AlertWidgetFormComponent;
  let vm;
  const props = {
    disabled: false,
  };

  beforeAll(() => {
    AlertWidgetFormComponent = Vue.extend(AlertWidgetForm);
  });

  afterEach(() => {
    if (vm) vm.$destroy();
  });

  it('disables the input when disabled prop is set', () => {
    vm = mountComponent(AlertWidgetFormComponent, { ...props, disabled: true });
    expect(vm.$refs.cancelButton).toBeDisabled();
    expect(vm.$refs.submitButton).toBeDisabled();
  });

  it('emits a "create" event when form submitted without existing alert', done => {
    vm = mountComponent(AlertWidgetFormComponent, props);
    expect(vm.$refs.submitButton.innerText).toContain('Add');
    vm.$once('create', alert => {
      expect(alert).toEqual({
        alert: null,
        operator: '<',
        threshold: 5,
      });
      done();
    });

    // the button should be disabled until an operator and threshold are selected
    expect(vm.$refs.submitButton).toBeDisabled();
    vm.operator = '<';
    vm.threshold = 5;
    Vue.nextTick(() => {
      vm.$refs.submitButton.click();
    });
  });

  it('emits a "delete" event when form submitted with existing alert and no changes are made', done => {
    vm = mountComponent(AlertWidgetFormComponent, {
      ...props,
      alert: 'alert',
      alertData: { operator: '<', threshold: 5 },
    });

    vm.$once('delete', alert => {
      expect(alert).toEqual({
        alert: 'alert',
        operator: '<',
        threshold: 5,
      });
      done();
    });

    expect(vm.$refs.submitButton.innerText).toContain('Delete');
    vm.$refs.submitButton.click();
  });

  it('emits a "update" event when form submitted with existing alert', done => {
    vm = mountComponent(AlertWidgetFormComponent, {
      ...props,
      alert: 'alert',
      alertData: { operator: '<', threshold: 5 },
    });
    expect(vm.$refs.submitButton.innerText).toContain('Delete');
    vm.$once('update', alert => {
      expect(alert).toEqual({
        alert: 'alert',
        operator: '=',
        threshold: 5,
      });
      done();
    });

    // change operator to allow update
    vm.operator = '=';
    Vue.nextTick(() => {
      expect(vm.$refs.submitButton.innerText).toContain('Save');
      vm.$refs.submitButton.click();
    });
  });
});
