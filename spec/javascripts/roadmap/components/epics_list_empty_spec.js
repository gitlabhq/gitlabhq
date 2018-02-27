import Vue from 'vue';

import epicsListEmptyComponent from 'ee/roadmap/components/epics_list_empty.vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockTimeframe, mockSvgPath } from '../mock_data';

const createComponent = () => {
  const Component = Vue.extend(epicsListEmptyComponent);

  return mountComponent(Component, {
    timeframeStart: mockTimeframe[0],
    timeframeEnd: mockTimeframe[mockTimeframe.length - 1],
    emptyStateIllustrationPath: mockSvgPath,
  });
};

describe('EpicsListEmptyComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('message', () => {
      it('returns correct empty state message', () => {
        expect(vm.message).toBe('Epics let you manage your portfolio of projects more efficiently and with less effort');
      });
    });

    describe('subMessage', () => {
      it('returns correct empty state sub-message', () => {
        expect(vm.subMessage).toBe('To view the roadmap, add a planned start or finish date to one of your epics in this group or its subgroups. Only epics in the past 3 months and the next 3 months are shown &ndash; from Nov 1, 2017 to Apr 30, 2018.');
      });
    });

    describe('timeframeRange', () => {
      it('returns correct timeframe startDate and endDate in words', () => {
        expect(vm.timeframeRange.startDate).toBe('Nov 1, 2017');
        expect(vm.timeframeRange.endDate).toBe('Apr 30, 2018');
      });
    });
  });

  describe('template', () => {
    it('renders empty state illustration in image element with provided `emptyStateIllustrationPath`', () => {
      expect(vm.$el.querySelector('.svg-content img').getAttribute('src')).toBe(vm.emptyStateIllustrationPath);
    });
  });
});
