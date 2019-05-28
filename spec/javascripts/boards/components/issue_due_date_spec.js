import Vue from 'vue';
import dateFormat from 'dateformat';
import IssueDueDate from '~/boards/components/issue_due_date.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Issue Due Date component', () => {
  let vm;
  let date;
  const Component = Vue.extend(IssueDueDate);
  const createComponent = (dueDate = new Date()) =>
    mountComponent(Component, { date: dateFormat(dueDate, 'yyyy-mm-dd', true) });

  beforeEach(() => {
    date = new Date();
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render "Today" if the due date is today', () => {
    const timeContainer = vm.$el.querySelector('time');

    expect(timeContainer.textContent.trim()).toEqual('Today');
  });

  it('should render "Yesterday" if the due date is yesterday', () => {
    date.setDate(date.getDate() - 1);
    vm = createComponent(date);

    expect(vm.$el.querySelector('time').textContent.trim()).toEqual('Yesterday');
  });

  it('should render "Tomorrow" if the due date is one day from now', () => {
    date.setDate(date.getDate() + 1);
    vm = createComponent(date);

    expect(vm.$el.querySelector('time').textContent.trim()).toEqual('Tomorrow');
  });

  it('should render day of the week if due date is one week away', () => {
    date.setDate(date.getDate() + 5);
    vm = createComponent(date);

    expect(vm.$el.querySelector('time').textContent.trim()).toEqual(dateFormat(date, 'dddd'));
  });

  it('should render month and day for other dates', () => {
    date.setDate(date.getDate() + 17);
    vm = createComponent(date);
    const today = new Date();
    const isDueInCurrentYear = today.getFullYear() === date.getFullYear();
    const format = isDueInCurrentYear ? 'mmm d' : 'mmm d, yyyy';

    expect(vm.$el.querySelector('time').textContent.trim()).toEqual(dateFormat(date, format));
  });

  it('should contain the correct `.text-danger` css class for overdue issue', () => {
    date.setDate(date.getDate() - 17);
    vm = createComponent(date);

    expect(vm.$el.querySelector('time').classList.contains('text-danger')).toEqual(true);
  });
});
