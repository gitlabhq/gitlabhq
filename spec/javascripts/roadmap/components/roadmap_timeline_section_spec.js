import Vue from 'vue';

import roadmapTimelineSectionComponent from 'ee/roadmap/components/roadmap_timeline_section.vue';
import eventHub from 'ee/roadmap/event_hub';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockEpic, mockTimeframe, mockShellWidth } from '../mock_data';

const createComponent = ({
  epics = [mockEpic],
  timeframe = mockTimeframe,
  shellWidth = mockShellWidth,
}) => {
  const Component = Vue.extend(roadmapTimelineSectionComponent);

  return mountComponent(Component, {
    epics,
    timeframe,
    shellWidth,
  });
};

describe('RoadmapTimelineSectionComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent({});
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      expect(vm.scrolledHeaderClass).toBe('');
    });
  });

  describe('computed', () => {
    describe('calcShellWidth', () => {
      it('returns shellWidth by deducting Scrollbar size', () => {
        // shellWidth is 2000 (as defined above in mockShellWidth)
        // SCROLLBAR_SIZE is 15 (as defined in app's constants.js)
        // Hence, calcShellWidth = shellWidth - SCROLLBAR_SIZE
        expect(vm.calcShellWidth).toBe(1985);
      });
    });

    describe('theadStyles', () => {
      it('returns style string for thead based on calcShellWidth', () => {
        expect(vm.theadStyles).toBe('width: 1985px;');
      });
    });
  });

  describe('methods', () => {
    describe('handleEpicsListScroll', () => {
      it('sets `scrolled-ahead` class on thead element based on provided scrollTop value', () => {
        // vm.$el.clientHeight is 0 during tests
        // hence any value greater than 0 should
        // update scrolledHeaderClass prop
        vm.handleEpicsListScroll(1);
        expect(vm.scrolledHeaderClass).toBe('scrolled-ahead');

        vm.handleEpicsListScroll(0);
        expect(vm.scrolledHeaderClass).toBe('');
      });
    });
  });

  describe('mounted', () => {
    it('binds `epicsListScrolled` event listener via eventHub', () => {
      spyOn(eventHub, '$on');
      const vmX = createComponent({});
      expect(eventHub.$on).toHaveBeenCalledWith('epicsListScrolled', jasmine.any(Function));
      vmX.$destroy();
    });
  });

  describe('beforeDestroy', () => {
    it('unbinds `epicsListScrolled` event listener via eventHub', () => {
      spyOn(eventHub, '$off');
      const vmX = createComponent({});
      vmX.$destroy();
      expect(eventHub.$off).toHaveBeenCalledWith('epicsListScrolled', jasmine.any(Function));
    });
  });

  describe('template', () => {
    it('renders component container element with class `roadmap-timeline-section`', () => {
      expect(vm.$el.classList.contains('roadmap-timeline-section')).toBe(true);
    });

    it('renders empty header cell element with class `timeline-header-blank`', () => {
      expect(vm.$el.querySelector('.timeline-header-blank')).not.toBeNull();
    });
  });
});
