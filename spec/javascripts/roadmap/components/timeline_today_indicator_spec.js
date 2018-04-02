import Vue from 'vue';

import timelineTodayIndicatorComponent from 'ee/roadmap/components/timeline_today_indicator.vue';
import eventHub from 'ee/roadmap/event_hub';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockTimeframe } from '../mock_data';

const mockCurrentDate = new Date(
  mockTimeframe[0].getFullYear(),
  mockTimeframe[0].getMonth(),
  15,
);

const createComponent = ({
  currentDate = mockCurrentDate,
  timeframeItem = mockTimeframe[0],
}) => {
  const Component = Vue.extend(timelineTodayIndicatorComponent);

  return mountComponent(Component, {
    currentDate,
    timeframeItem,
  });
};

describe('TimelineTodayIndicatorComponent', () => {
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      vm = createComponent({});
      expect(vm.todayBarStyles).toBe('');
      expect(vm.todayBarReady).toBe(false);
    });
  });

  describe('methods', () => {
    describe('handleEpicsListRender', () => {
      it('sets `todayBarStyles` and `todayBarReady` props based on provided height param, timeframeItem and currentDate props', () => {
        vm = createComponent({});
        vm.handleEpicsListRender({
          height: 100,
        });
        const stylesObj = vm.todayBarStyles;
        expect(stylesObj.height).toBe('120px');
        expect(stylesObj.left).toBe('50%');
        expect(vm.todayBarReady).toBe(true);
      });
    });
  });

  describe('mounted', () => {
    it('binds `epicsListRendered` event listener via eventHub', () => {
      spyOn(eventHub, '$on');
      const vmX = createComponent({});
      expect(eventHub.$on).toHaveBeenCalledWith('epicsListRendered', jasmine.any(Function));
      vmX.$destroy();
    });
  });

  describe('beforeDestroy', () => {
    it('unbinds `epicsListRendered` event listener via eventHub', () => {
      spyOn(eventHub, '$off');
      const vmX = createComponent({});
      vmX.$destroy();
      expect(eventHub.$off).toHaveBeenCalledWith('epicsListRendered', jasmine.any(Function));
    });
  });

  describe('template', () => {
    it('renders component container element with class `today-bar`', (done) => {
      vm = createComponent({});
      vm.handleEpicsListRender({
        height: 100,
      });
      vm.$nextTick(() => {
        expect(vm.$el.classList.contains('today-bar')).toBe(true);
        done();
      });
    });
  });
});

