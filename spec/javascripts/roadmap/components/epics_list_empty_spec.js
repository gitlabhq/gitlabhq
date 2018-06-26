import Vue from 'vue';

import epicsListEmptyComponent from 'ee/roadmap/components/epics_list_empty.vue';

import { PRESET_TYPES } from 'ee/roadmap/constants';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import {
  mockTimeframeQuarters,
  mockTimeframeMonths,
  mockTimeframeWeeks,
  mockSvgPath,
  mockNewEpicEndpoint,
} from '../mock_data';

const createComponent = ({
  hasFiltersApplied = false,
  presetType = PRESET_TYPES.MONTHS,
  timeframeStart = mockTimeframeMonths[0],
  timeframeEnd = mockTimeframeMonths[mockTimeframeMonths.length - 1],
}) => {
  const Component = Vue.extend(epicsListEmptyComponent);

  return mountComponent(Component, {
    presetType,
    timeframeStart,
    timeframeEnd,
    emptyStateIllustrationPath: mockSvgPath,
    newEpicEndpoint: mockNewEpicEndpoint,
    hasFiltersApplied,
  });
};

describe('EpicsListEmptyComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent({});
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('message', () => {
      it('returns default empty state message', () => {
        expect(vm.message).toBe('The roadmap shows the progress of your epics along a timeline');
      });

      it('returns empty state message when `hasFiltersApplied` prop is true', (done) => {
        vm.hasFiltersApplied = true;
        Vue.nextTick()
          .then(() => {
            expect(vm.message).toBe('Sorry, no epics matched your search');
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('subMessage', () => {
      describe('with presetType `QUARTERS`', () => {
        beforeEach(() => {
          vm.presetType = PRESET_TYPES.QUARTERS;
          [vm.timeframeStart] = mockTimeframeQuarters;
          vm.timeframeEnd = mockTimeframeQuarters[mockTimeframeQuarters.length - 1];
        });

        it('returns default empty state sub-message when `hasFiltersApplied` props is false', done => {
          Vue.nextTick()
            .then(() => {
              expect(vm.subMessage).toBe('To view the roadmap, add a planned start or finish date to one of your epics in this group or its subgroups. In the quarters view, only epics in the past quarter, current quarter, and next 4 quarters are shown &ndash; from Oct 1, 2017 to Mar 31, 2019.');
            })
            .then(done)
            .catch(done.fail);
        });

        it('returns empty state sub-message when `hasFiltersApplied` prop is true', done => {
          vm.hasFiltersApplied = true;
          Vue.nextTick()
            .then(() => {
              expect(vm.subMessage).toBe('To widen your search, change or remove filters. In the quarters view, only epics in the past quarter, current quarter, and next 4 quarters are shown &ndash; from Oct 1, 2017 to Mar 31, 2019.');
            })
            .then(done)
            .catch(done.fail);
        });
      });

      describe('with presetType `MONTHS`', () => {
        beforeEach(() => {
          vm.presetType = PRESET_TYPES.MONTHS;
        });

        it('returns default empty state sub-message when `hasFiltersApplied` props is false', done => {
          Vue.nextTick()
            .then(() => {
              expect(vm.subMessage).toBe('To view the roadmap, add a planned start or finish date to one of your epics in this group or its subgroups. In the months view, only epics in the past month, current month, and next 5 months are shown &ndash; from Dec 1, 2017 to Jun 30, 2018.');
            })
            .then(done)
            .catch(done.fail);
        });

        it('returns empty state sub-message when `hasFiltersApplied` prop is true', done => {
          vm.hasFiltersApplied = true;
          Vue.nextTick()
            .then(() => {
              expect(vm.subMessage).toBe('To widen your search, change or remove filters. In the months view, only epics in the past month, current month, and next 5 months are shown &ndash; from Dec 1, 2017 to Jun 30, 2018.');
            })
            .then(done)
            .catch(done.fail);
        });
      });

      describe('with presetType `WEEKS`', () => {
        beforeEach(() => {
          const timeframeEnd = mockTimeframeWeeks[mockTimeframeWeeks.length - 1];
          timeframeEnd.setDate(timeframeEnd.getDate() + 6);

          vm.presetType = PRESET_TYPES.WEEKS;
          [vm.timeframeStart] = mockTimeframeWeeks;
          vm.timeframeEnd = timeframeEnd;
        });

        it('returns default empty state sub-message when `hasFiltersApplied` props is false', done => {
          Vue.nextTick()
            .then(() => {
              expect(vm.subMessage).toBe('To view the roadmap, add a planned start or finish date to one of your epics in this group or its subgroups. In the weeks view, only epics in the past week, current week, and next 4 weeks are shown &ndash; from Dec 24, 2017 to Feb 9, 2018.');
            })
            .then(done)
            .catch(done.fail);
        });

        it('returns empty state sub-message when `hasFiltersApplied` prop is true', done => {
          vm.hasFiltersApplied = true;
          Vue.nextTick()
            .then(() => {
              expect(vm.subMessage).toBe('To widen your search, change or remove filters. In the weeks view, only epics in the past week, current week, and next 4 weeks are shown &ndash; from Dec 24, 2017 to Feb 15, 2018.');
            })
            .then(done)
            .catch(done.fail);
        });
      });
    });

    describe('timeframeRange', () => {
      it('returns correct timeframe startDate and endDate in words', () => {
        expect(vm.timeframeRange.startDate).toBe('Dec 1, 2017');
        expect(vm.timeframeRange.endDate).toBe('Jun 30, 2018');
      });
    });
  });

  describe('template', () => {
    it('renders empty state illustration in image element with provided `emptyStateIllustrationPath`', () => {
      expect(vm.$el.querySelector('.svg-content img').getAttribute('src')).toBe(vm.emptyStateIllustrationPath);
    });

    it('renders new epic button element', () => {
      const newEpicBtnEl = vm.$el.querySelector('.new-epic-dropdown');

      expect(newEpicBtnEl).not.toBeNull();
      expect(newEpicBtnEl.querySelector('button.btn-new').innerText.trim()).toBe('New epic');
    });

    it('does not render new epic button element when `hasFiltersApplied` prop is true', done => {
      vm.hasFiltersApplied = true;
      Vue.nextTick()
        .then(() => {
          expect(vm.$el.querySelector('.new-epic-dropdown')).toBeNull();
        })
        .then(done)
        .catch(done.fail);
    });

    it('renders view epics list link element', () => {
      const viewEpicsListEl = vm.$el.querySelector('a.btn');

      expect(viewEpicsListEl).not.toBeNull();
      expect(viewEpicsListEl.getAttribute('href')).toBe(mockNewEpicEndpoint);
      expect(viewEpicsListEl.querySelector('span').innerText.trim()).toBe('View epics list');
    });
  });
});
