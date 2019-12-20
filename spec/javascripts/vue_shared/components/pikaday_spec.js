import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import datePicker from '~/vue_shared/components/pikaday.vue';

describe('datePicker', () => {
  let vm;
  beforeEach(() => {
    const DatePicker = Vue.extend(datePicker);
    vm = mountComponent(DatePicker, {
      label: 'label',
    });
  });

  it('should render label text', () => {
    expect(vm.$el.querySelector('.dropdown-toggle-text').innerText.trim()).toEqual('label');
  });

  it('should show calendar', () => {
    expect(vm.$el.querySelector('.pika-single')).toBeDefined();
  });

  it('should toggle when dropdown is clicked', () => {
    const hidePicker = jasmine.createSpy();
    vm.$on('hidePicker', hidePicker);

    vm.$el.querySelector('.dropdown-menu-toggle').click();

    expect(hidePicker).toHaveBeenCalled();
  });
});
