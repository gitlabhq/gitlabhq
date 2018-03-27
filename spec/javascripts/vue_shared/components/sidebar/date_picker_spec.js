import Vue from 'vue';
import sidebarDatePicker from '~/vue_shared/components/sidebar/date_picker.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('sidebarDatePicker', () => {
  let vm;
  beforeEach(() => {
    const SidebarDatePicker = Vue.extend(sidebarDatePicker);
    vm = mountComponent(SidebarDatePicker, {
      label: 'label',
      isLoading: true,
    });
  });

  it('should emit toggleCollapse when collapsed toggle sidebar is clicked', () => {
    const toggleCollapse = jasmine.createSpy();
    vm.$on('toggleCollapse', toggleCollapse);

    vm.$el.querySelector('.issuable-sidebar-header .gutter-toggle').click();
    expect(toggleCollapse).toHaveBeenCalled();
  });

  it('should render collapsed-calendar-icon', () => {
    expect(vm.$el.querySelector('.sidebar-collapsed-icon')).toBeDefined();
  });

  it('should render label', () => {
    expect(vm.$el.querySelector('.title').innerText.trim()).toEqual('label');
  });

  it('should render loading-icon when isLoading', () => {
    expect(vm.$el.querySelector('.fa-spin')).toBeDefined();
  });

  it('should render value when not editing', () => {
    expect(vm.$el.querySelector('.value-content')).toBeDefined();
  });

  it('should render None if there is no selectedDate', () => {
    expect(vm.$el.querySelector('.value-content span').innerText.trim()).toEqual('None');
  });

  it('should render date-picker when editing', (done) => {
    vm.editing = true;
    Vue.nextTick(() => {
      expect(vm.$el.querySelector('.pika-label')).toBeDefined();
      done();
    });
  });

  describe('editable', () => {
    beforeEach((done) => {
      vm.editable = true;
      Vue.nextTick(done);
    });

    it('should render edit button', () => {
      expect(vm.$el.querySelector('.title .btn-blank').innerText.trim()).toEqual('Edit');
    });

    it('should enable editing when edit button is clicked', (done) => {
      vm.isLoading = false;
      Vue.nextTick(() => {
        vm.$el.querySelector('.title .btn-blank').click();
        expect(vm.editing).toEqual(true);
        done();
      });
    });
  });

  it('should render date if selectedDate', (done) => {
    vm.selectedDate = new Date('07/07/2017');
    Vue.nextTick(() => {
      expect(vm.$el.querySelector('.value-content strong').innerText.trim()).toEqual('Jul 7, 2017');
      done();
    });
  });

  describe('selectedDate and editable', () => {
    beforeEach((done) => {
      vm.selectedDate = new Date('07/07/2017');
      vm.editable = true;
      Vue.nextTick(done);
    });

    it('should render remove button if selectedDate and editable', () => {
      expect(vm.$el.querySelector('.value-content .btn-blank').innerText.trim()).toEqual('remove');
    });

    it('should emit saveDate when remove button is clicked', () => {
      const saveDate = jasmine.createSpy();
      vm.$on('saveDate', saveDate);

      vm.$el.querySelector('.value-content .btn-blank').click();
      expect(saveDate).toHaveBeenCalled();
    });
  });

  describe('showToggleSidebar', () => {
    beforeEach((done) => {
      vm.showToggleSidebar = true;
      Vue.nextTick(done);
    });

    it('should render toggle-sidebar when showToggleSidebar', () => {
      expect(vm.$el.querySelector('.title .gutter-toggle')).toBeDefined();
    });

    it('should emit toggleCollapse when toggle sidebar is clicked', () => {
      const toggleCollapse = jasmine.createSpy();
      vm.$on('toggleCollapse', toggleCollapse);

      vm.$el.querySelector('.title .gutter-toggle').click();
      expect(toggleCollapse).toHaveBeenCalled();
    });
  });
});
