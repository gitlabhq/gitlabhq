import Vue from 'vue';
import dateFormat from 'dateformat';
import issueDueDate from '../../../../app/assets/javascripts/boards/components/issue_due_date.vue';

describe('Issue Due Date component', () => {
  let IssueDueDate;
  let vm;

  beforeEach(() => {
    IssueDueDate = Vue.extend(issueDueDate);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render "Today" if the due date is today', () => {
    const today = dateFormat(new Date(), 'yyyy-mm-dd', true);
    vm = new IssueDueDate({
      propsData: {
        date: today,
      },
    }).$mount();

    expect(vm.$el.textContent.trim()).toEqual('Today');
  });

  it('should render "Yesterday" if the due date is yesterday', () => {
    const date = new Date();
    date.setDate(date.getDate() - 1);
    const yesterday = dateFormat(date, 'yyyy-mm-dd', true);
    vm = new IssueDueDate({
      propsData: {
        date: yesterday,
      },
    }).$mount();

    expect(vm.$el.textContent.trim()).toEqual('Yesterday');
  });

  it('should render day of the week if due date is one week away', () => {
    const date = new Date();
    date.setDate(date.getDate() + 5);
    const dueDate = dateFormat(date, 'yyyy-mm-dd', true);
    vm = new IssueDueDate({
      propsData: {
        date: dueDate,
      },
    }).$mount();

    expect(vm.$el.textContent.trim()).toEqual(dateFormat(dueDate, 'dddd', true));
  });

  it('should render month and day for other dates', () => {
    const date = new Date();
    date.setDate(date.getDate() + 17);
    const dueDate = dateFormat(date, 'yyyy-mm-dd', true);
    vm = new IssueDueDate({
      propsData: {
        date: dueDate,
      },
    }).$mount();

    expect(vm.$el.textContent.trim()).toEqual(dateFormat(dueDate, 'mmm d', true));
  });

  it('should contain the correct class for overdue issue', () => {
    const date = new Date();
    date.setDate(date.getDate() - 17);
    const dueDate = dateFormat(date, 'yyyy-mm-dd', true);
    vm = new IssueDueDate({
      propsData: {
        date: dueDate,
      },
    }).$mount();

    expect(vm.$el.classList.contains('text-danger')).toEqual(true);
  });

  it('should render month, day and year when due date is not current year', () => {
    const date = new Date();
    date.setDate(date.getDate() + 365);
    const dueDate = dateFormat(date, 'yyyy-mm-dd', true);
    vm = new IssueDueDate({
      propsData: {
        date: dueDate,
      },
    }).$mount();

    expect(vm.$el.textContent.trim()).toEqual(dateFormat(dueDate, 'mmm d, yyyy', true));
  });
});
