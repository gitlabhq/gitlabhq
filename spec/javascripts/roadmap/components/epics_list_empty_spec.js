import Vue from 'vue';

import epicsListEmptyComponent from 'ee/roadmap/components/epics_list_empty.vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockTimeframe, mockSvgPath, mockNewEpicEndpoint } from '../mock_data';

const createComponent = (hasFiltersApplied = false) => {
  const Component = Vue.extend(epicsListEmptyComponent);

  return mountComponent(Component, {
    timeframeStart: mockTimeframe[0],
    timeframeEnd: mockTimeframe[mockTimeframe.length - 1],
    emptyStateIllustrationPath: mockSvgPath,
    newEpicEndpoint: mockNewEpicEndpoint,
    hasFiltersApplied,
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
      it('returns default empty state sub-message', () => {
        expect(vm.subMessage).toBe('To view the roadmap, add a planned start or finish date to one of your epics in this group or its subgroups. Only epics in the past 3 months and the next 3 months are shown &ndash; from Nov 1, 2017 to Apr 30, 2018.');
      });

      it('returns empty state sub-message when `hasFiltersApplied` prop is true', done => {
        vm.hasFiltersApplied = true;
        Vue.nextTick()
          .then(() => {
            expect(vm.subMessage).toBe('To widen your search, change or remove filters. Only epics in the past 3 months and the next 3 months are shown &ndash; from Nov 1, 2017 to Apr 30, 2018.');
          })
          .then(done)
          .catch(done.fail);
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
