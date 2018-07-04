import Vue from 'vue';

import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';

import appComponent from 'ee/roadmap/components/app.vue';
import RoadmapStore from 'ee/roadmap/store/roadmap_store';
import RoadmapService from 'ee/roadmap/service/roadmap_service';

import { PRESET_TYPES } from 'ee/roadmap/constants';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockTimeframeMonths, mockGroupId, epicsPath, mockNewEpicEndpoint, rawEpics, mockSvgPath } from '../mock_data';

const createComponent = () => {
  const Component = Vue.extend(appComponent);
  const timeframe = mockTimeframeMonths;

  const store = new RoadmapStore(mockGroupId, timeframe);
  const service = new RoadmapService(epicsPath);

  return mountComponent(Component, {
    store,
    service,
    presetType: PRESET_TYPES.MONTHS,
    hasFiltersApplied: true,
    newEpicEndpoint: mockNewEpicEndpoint,
    emptyStateIllustrationPath: mockSvgPath,
  });
};

describe('AppComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      expect(vm.isLoading).toBe(true);
      expect(vm.isEpicsListEmpty).toBe(false);
      expect(vm.hasError).toBe(false);
      expect(vm.handleResizeThrottled).toBeDefined();
    });
  });

  describe('computed', () => {
    describe('epics', () => {
      it('returns array of epics', () => {
        expect(Array.isArray(vm.epics)).toBe(true);
      });
    });

    describe('timeframe', () => {
      it('returns array of timeframe', () => {
        expect(Array.isArray(vm.timeframe)).toBe(true);
      });
    });

    describe('timeframeStart', () => {
      it('returns first item of timeframe array', () => {
        expect(vm.timeframeStart instanceof Date).toBe(true);
      });
    });

    describe('timeframeEnd', () => {
      it('returns last item of timeframe array', () => {
        expect(vm.timeframeEnd instanceof Date).toBe(true);
      });
    });

    describe('currentGroupId', () => {
      it('returns current group Id', () => {
        expect(vm.currentGroupId).toBe(mockGroupId);
      });
    });

    describe('showRoadmap', () => {
      it('returns true if `isLoading`, `isEpicsListEmpty` and `hasError` are all `false`', () => {
        vm.isLoading = false;
        vm.isEpicsListEmpty = false;
        vm.hasError = false;
        expect(vm.showRoadmap).toBe(true);
      });

      it('returns false if either of `isLoading`, `isEpicsListEmpty` and `hasError` is `true`', () => {
        vm.isLoading = true;
        vm.isEpicsListEmpty = false;
        vm.hasError = false;
        expect(vm.showRoadmap).toBe(false);
        vm.isLoading = false;
        vm.isEpicsListEmpty = true;
        vm.hasError = false;
        expect(vm.showRoadmap).toBe(false);
        vm.isLoading = false;
        vm.isEpicsListEmpty = false;
        vm.hasError = true;
        expect(vm.showRoadmap).toBe(false);
      });
    });
  });

  describe('methods', () => {
    describe('fetchEpics', () => {
      let mock;

      beforeEach(() => {
        mock = new MockAdapter(axios);
        document.body.innerHTML += '<div class="flash-container"></div>';
      });

      afterEach(() => {
        mock.restore();
        document.querySelector('.flash-container').remove();
      });

      it('calls service.getEpics and sets response to the store on success', (done) => {
        mock.onGet(vm.service.epicsPath).reply(200, rawEpics);
        spyOn(vm.store, 'setEpics');

        vm.fetchEpics();
        expect(vm.hasError).toBe(false);
        setTimeout(() => {
          expect(vm.isLoading).toBe(false);
          expect(vm.store.setEpics).toHaveBeenCalledWith(rawEpics);
          done();
        }, 0);
      });

      it('calls service.getEpics and sets `isEpicsListEmpty` to true if response is empty', (done) => {
        mock.onGet(vm.service.epicsPath).reply(200, []);
        spyOn(vm.store, 'setEpics');

        vm.fetchEpics();
        expect(vm.isEpicsListEmpty).toBe(false);
        setTimeout(() => {
          expect(vm.isEpicsListEmpty).toBe(true);
          expect(vm.store.setEpics).not.toHaveBeenCalled();
          done();
        }, 0);
      });

      it('calls service.getEpics and sets `hasError` to true and shows flash message if request failed', (done) => {
        mock.onGet(vm.service.epicsPath).reply(500, {});

        vm.fetchEpics();
        expect(vm.hasError).toBe(false);
        setTimeout(() => {
          expect(vm.hasError).toBe(true);
          expect(document.querySelector('.flash-text').innerText.trim()).toBe('Something went wrong while fetching epics');
          done();
        }, 0);
      });
    });
  });

  describe('mounted', () => {
    it('binds window resize event listener', () => {
      spyOn(window, 'addEventListener');
      const vmX = createComponent();

      expect(vmX.handleResizeThrottled).toBeDefined();
      expect(window.addEventListener).toHaveBeenCalledWith('resize', vmX.handleResizeThrottled, false);
      vmX.$destroy();
    });
  });

  describe('beforeDestroy', () => {
    it('unbinds window resize event listener', () => {
      spyOn(window, 'removeEventListener');
      const vmX = createComponent();
      vmX.$destroy();

      expect(window.removeEventListener).toHaveBeenCalledWith('resize', vmX.handleResizeThrottled, false);
    });
  });

  describe('template', () => {
    it('renders roadmap container with class `roadmap-container`', () => {
      expect(vm.$el.classList.contains('roadmap-container')).toBe(true);
    });

    it('renders roadmap container with classes `roadmap-container overflow-reset` when isEpicsListEmpty prop is true', (done) => {
      vm.isEpicsListEmpty = true;
      Vue.nextTick()
        .then(() => {
          expect(vm.$el.classList.contains('roadmap-container')).toBe(true);
          expect(vm.$el.classList.contains('overflow-reset')).toBe(true);
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
