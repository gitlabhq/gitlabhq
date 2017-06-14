import Vue from 'vue';
import timeAgo from '~/pipelines/components/time_ago.vue';

describe('Timeago component', () => {
  let TimeAgo;
  beforeEach(() => {
    TimeAgo = Vue.extend(timeAgo);
  });

  describe('with duration', () => {
    it('should render duration and timer svg', () => {
      const component = new TimeAgo({
        propsData: {
          duration: 10,
          finishedTime: '',
        },
      }).$mount();

      expect(component.$el.querySelector('.duration')).toBeDefined();
      expect(component.$el.querySelector('.duration svg')).toBeDefined();
    });
  });

  describe('without duration', () => {
    it('should not render duration and timer svg', () => {
      const component = new TimeAgo({
        propsData: {
          duration: 0,
          finishedTime: '',
        },
      }).$mount();

      expect(component.$el.querySelector('.duration')).toBe(null);
    });
  });

  describe('with finishedTime', () => {
    it('should render time and calendar icon', () => {
      const component = new TimeAgo({
        propsData: {
          duration: 0,
          finishedTime: '2017-04-26T12:40:23.277Z',
        },
      }).$mount();

      expect(component.$el.querySelector('.finished-at')).toBeDefined();
      expect(component.$el.querySelector('.finished-at i.fa-calendar')).toBeDefined();
      expect(component.$el.querySelector('.finished-at time')).toBeDefined();
    });
  });

  describe('without finishedTime', () => {
    it('should not render time and calendar icon', () => {
      const component = new TimeAgo({
        propsData: {
          duration: 0,
          finishedTime: '',
        },
      }).$mount();

      expect(component.$el.querySelector('.finished-at')).toBe(null);
    });
  });
});
