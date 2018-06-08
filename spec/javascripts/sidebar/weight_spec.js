import Vue from 'vue';
import weight from 'ee/sidebar/components/weight/weight.vue';
import eventHub from '~/sidebar/event_hub';
import { ENTER_KEY_CODE } from '~/lib/utils/keycodes';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

const DEFAULT_PROPS = {
  weightNoneValue: 'None',
};

describe('Weight', function() {
  let vm;
  let Weight;

  beforeEach(() => {
    Weight = Vue.extend(weight);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('shows loading spinner when fetching', () => {
    vm = mountComponent(Weight, {
      ...DEFAULT_PROPS,
      fetching: true,
    });

    expect(vm.$el.querySelector('.js-weight-collapsed-loading-icon')).not.toBeNull();
    expect(vm.$el.querySelector('.js-weight-loading-icon')).not.toBeNull();
  });

  it('shows loading spinner when loading', () => {
    vm = mountComponent(Weight, {
      ...DEFAULT_PROPS,
      fetching: false,
      loading: true,
    });

    // We show the value in the collapsed view instead of the loading icon
    expect(vm.$el.querySelector('.js-weight-collapsed-loading-icon')).toBeNull();
    expect(vm.$el.querySelector('.js-weight-loading-icon')).not.toBeNull();
  });

  it('shows weight value', () => {
    const WEIGHT = 3;
    vm = mountComponent(Weight, {
      ...DEFAULT_PROPS,
      fetching: false,
      weight: WEIGHT,
    });

    expect(vm.$el.querySelector('.js-weight-collapsed-weight-label').textContent.trim()).toEqual(
      `${WEIGHT}`,
    );
    expect(vm.$el.querySelector('.js-weight-weight-label-value').textContent.trim()).toEqual(
      `${WEIGHT}`,
    );
  });

  it('shows weight no-value', () => {
    const WEIGHT = null;
    vm = mountComponent(Weight, {
      ...DEFAULT_PROPS,
      fetching: false,
      weight: WEIGHT,
    });

    expect(vm.$el.querySelector('.js-weight-collapsed-weight-label').textContent.trim()).toEqual(
      'None',
    );
    expect(vm.$el.querySelector('.js-weight-weight-label .no-value').textContent.trim()).toEqual(
      'None',
    );
  });

  it('adds `collapse-after-update` class when clicking the collapsed block', done => {
    vm = mountComponent(Weight, {
      ...DEFAULT_PROPS,
    });

    vm.$el.querySelector('.js-weight-collapsed-block').click();

    vm
      .$nextTick()
      .then(() => {
        expect(vm.$el.classList.contains('collapse-after-update')).toEqual(true);
      })
      .then(done)
      .catch(done.fail);
  });

  it('shows dropdown on "Edit" link click', done => {
    vm = mountComponent(Weight, {
      ...DEFAULT_PROPS,
      editable: true,
    });

    expect(vm.shouldShowEditField).toEqual(false);

    vm.$el.querySelector('.js-weight-edit-link').click();

    vm
      .$nextTick()
      .then(() => {
        expect(vm.shouldShowEditField).toEqual(true);
      })
      .then(done)
      .catch(done.fail);
  });

  it('emits event on input submission', done => {
    const ID = 123;
    const expectedWeightValue = '3';
    spyOn(eventHub, '$emit');
    vm = mountComponent(Weight, {
      ...DEFAULT_PROPS,
      editable: true,
      id: ID,
    });

    vm.$el.querySelector('.js-weight-edit-link').click();

    vm.$nextTick(() => {
      const event = new CustomEvent('keydown');
      event.keyCode = ENTER_KEY_CODE;

      vm.$refs.editableField.click();
      vm.$refs.editableField.value = expectedWeightValue;
      vm.$refs.editableField.dispatchEvent(event);

      expect(vm.hasValidInput).toBe(true);
      expect(eventHub.$emit).toHaveBeenCalledWith('updateWeight', expectedWeightValue, ID);
      done();
    });
  });

  it('emits event on remove weight link click', done => {
    const ID = 123;
    spyOn(eventHub, '$emit');
    vm = mountComponent(Weight, {
      ...DEFAULT_PROPS,
      editable: true,
      weight: 3,
      id: ID,
    });

    vm.$el.querySelector('.js-weight-remove-link').click();

    vm.$nextTick(() => {
      expect(vm.hasValidInput).toBe(true);
      expect(eventHub.$emit).toHaveBeenCalledWith('updateWeight', '', ID);
      done();
    });
  });

  it('triggers error on invalid string value', done => {
    vm = mountComponent(Weight, {
      ...DEFAULT_PROPS,
      editable: true,
    });

    vm.$el.querySelector('.js-weight-edit-link').click();

    vm.$nextTick(() => {
      const event = new CustomEvent('keydown');
      event.keyCode = ENTER_KEY_CODE;

      vm.$refs.editableField.click();
      vm.$refs.editableField.value = 'potato';
      vm.$refs.editableField.dispatchEvent(event);

      expect(vm.hasValidInput).toBe(false);
      done();
    });
  });

  it('triggers error on invalid negative integer value', done => {
    vm = mountComponent(Weight, {
      ...DEFAULT_PROPS,
      editable: true,
    });

    vm.$el.querySelector('.js-weight-edit-link').click();

    vm.$nextTick(() => {
      const event = new CustomEvent('keydown');
      event.keyCode = ENTER_KEY_CODE;

      vm.$refs.editableField.click();
      vm.$refs.editableField.value = -9001;
      vm.$refs.editableField.dispatchEvent(event);

      expect(vm.hasValidInput).toBe(false);
      done();
    });
  });
});
