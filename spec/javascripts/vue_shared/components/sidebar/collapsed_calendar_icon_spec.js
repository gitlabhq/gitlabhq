import Vue from 'vue';
import collapsedCalendarIcon from '~/vue_shared/components/sidebar/collapsed_calendar_icon.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('collapsedCalendarIcon', () => {
  let vm;
  beforeEach(() => {
    const CollapsedCalendarIcon = Vue.extend(collapsedCalendarIcon);
    vm = mountComponent(CollapsedCalendarIcon, {
      containerClass: 'test-class',
      text: 'text',
      showIcon: false,
    });
  });

  it('should add class to container', () => {
    expect(vm.$el.classList.contains('test-class')).toEqual(true);
  });

  it('should hide calendar icon if showIcon', () => {
    expect(vm.$el.querySelector('.fa-calendar')).toBeNull();
  });

  it('should render text', () => {
    expect(vm.$el.querySelector('span').innerText.trim()).toEqual('text');
  });

  it('should emit click event when container is clicked', () => {
    const click = jasmine.createSpy();
    vm.$on('click', click);

    vm.$el.click();
    expect(click).toHaveBeenCalled();
  });
});
