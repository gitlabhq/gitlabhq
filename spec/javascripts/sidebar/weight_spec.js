import Vue from 'vue';
import weight from 'ee/sidebar/components/weight/weight.vue';
import eventHub from '~/sidebar/event_hub';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import getSetTimeoutPromise from 'spec/helpers/set_timeout_promise_helper';

const DEFAULT_PROPS = {
  weightOptions: ['No Weight', 1, 2, 3],
  weightNoneValue: 'No Weight',
};

describe('Weight', function () {
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

    expect(vm.$el.querySelector('.js-weight-collapsed-weight-label').textContent.trim()).toEqual(`${WEIGHT}`);
    expect(vm.$el.querySelector('.js-weight-weight-label').textContent.trim()).toEqual(`${WEIGHT}`);
    expect(vm.$el.querySelector('.js-weight-dropdown-toggle-text').textContent.trim()).toEqual(`${WEIGHT}`);
  });

  it('shows weight no-value', () => {
    const WEIGHT = null;
    vm = mountComponent(Weight, {
      ...DEFAULT_PROPS,
      fetching: false,
      weight: WEIGHT,
    });

    expect(vm.$el.querySelector('.js-weight-collapsed-weight-label').textContent.trim()).toEqual('No');
    expect(vm.$el.querySelector('.js-weight-weight-label').textContent.trim()).toEqual('None');
    // Put a placeholder in the dropdown toggle
    expect(vm.$el.querySelector('.js-weight-dropdown-toggle-text').textContent.trim()).toEqual('Weight');
  });

  it('adds `collapse-after-update` class when clicking the collapsed block', (done) => {
    vm = mountComponent(Weight, {
      ...DEFAULT_PROPS,
    });

    vm.$el.querySelector('.js-weight-collapsed-block').click();

    vm.$nextTick()
      .then(() => {
        expect(vm.$el.classList.contains('collapse-after-update')).toEqual(true);
      })
      .then(done)
      .catch(done.fail);
  });

  it('shows dropdown on "Edit" link click', (done) => {
    vm = mountComponent(Weight, {
      ...DEFAULT_PROPS,
      editable: true,
    });

    expect(vm.shouldShowDropdown).toEqual(false);

    vm.$el.querySelector('.js-weight-edit-link').click();

    vm.$nextTick()
      .then(() => {
        expect(vm.shouldShowDropdown).toEqual(true);
      })
      .then(done)
      .catch(done.fail);
  });

  it('emits event on dropdown item click', (done) => {
    const ID = 123;
    spyOn(eventHub, '$emit');
    vm = mountComponent(Weight, {
      ...DEFAULT_PROPS,
      editable: true,
      id: ID,
    });

    vm.$el.querySelector('.js-weight-edit-link').click();

    vm.$nextTick()
      .then(() => getSetTimeoutPromise())
      .then(() => {
        vm.$el.querySelector('.js-weight-dropdown-content li:nth-child(2) a').click();
      })
      .then(() => {
        expect(eventHub.$emit).toHaveBeenCalledWith('updateWeight', DEFAULT_PROPS.weightOptions[1], ID);
      })
      .then(done)
      .catch(done.fail);
  });
});
