import Vue from 'vue';
import dateFormat from 'dateformat';
import IssueDueDate from '../../../../app/assets/javascripts/boards/components/issue_due_date.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Issue Due Date component', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(IssueDueDate);
    vm = mountComponent(Component, {
      date: dateFormat(new Date(), 'yyyy-mm-dd', true),
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render "Today" if the due date is today', () => {
    expect(vm.$el.textContent.trim()).toEqual('Today');
  });

  it('should render "Yesterday" if the due date is yesterday', (done) => {
    const date = new Date();
    date.setDate(date.getDate() - 1);
    const yesterday = dateFormat(date, 'yyyy-mm-dd', true);
    vm.date = yesterday;

    Vue.nextTick(() => {
      expect(vm.$el.textContent.trim()).toEqual('Yesterday');
      done();
    });
  });

  it('should render "Tomorrow" if the due date is one day from now', (done) => {
    const date = new Date();
    date.setDate(date.getDate() + 1);
    const tomorrow = dateFormat(date, 'yyyy-mm-dd', true);
    vm.date = tomorrow;

    Vue.nextTick(() => {
      expect(vm.$el.textContent.trim()).toEqual('Tomorrow');
      done();
    });
  });

  it('should render day of the week if due date is one week away', (done) => {
    const date = new Date();
    date.setDate(date.getDate() + 5);
    const dueDate = dateFormat(date, 'yyyy-mm-dd', true);
    vm.date = dueDate;

    Vue.nextTick(() => {
      expect(vm.$el.textContent.trim()).toEqual(dateFormat(dueDate, 'dddd', true));
      done();
    });
  });

  it('should render month and day for other dates', (done) => {
    const date = new Date();
    date.setDate(date.getDate() + 17);
    const dueDate = dateFormat(date, 'yyyy-mm-dd', true);
    vm.date = dueDate;

    Vue.nextTick(() => {
      expect(vm.$el.textContent.trim()).toEqual(dateFormat(dueDate, 'mmm d', true));
      done();
    });
  });

  it('should contain the correct `.text-danger` css class for overdue issue', (done) => {
    const date = new Date();
    date.setDate(date.getDate() - 17);
    const dueDate = dateFormat(date, 'yyyy-mm-dd', true);
    vm.date = dueDate;

    const $timeContainer = vm.$el.querySelector('time');

    Vue.nextTick(() => {
      expect($timeContainer.classList.contains('text-danger')).toEqual(true);
      done();
    });
  });
});
