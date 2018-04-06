import Vue from 'vue';

import roadmapShellComponent from 'ee/roadmap/components/roadmap_shell.vue';
import eventHub from 'ee/roadmap/event_hub';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockEpic, mockTimeframe, mockGroupId, mockScrollBarSize } from '../mock_data';

const createComponent = ({
  epics = [mockEpic],
  timeframe = mockTimeframe,
  currentGroupId = mockGroupId,
}, el) => {
  const Component = Vue.extend(roadmapShellComponent);

  return mountComponent(Component, {
    epics,
    timeframe,
    currentGroupId,
  }, el);
};

describe('RoadmapShellComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent({});
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      expect(vm.shellWidth).toBe(0);
      expect(vm.shellHeight).toBe(0);
      expect(vm.noScroll).toBe(false);
    });
  });

  describe('computed', () => {
    describe('containerStyles', () => {
      beforeEach(() => {
        document.body.innerHTML += '<div class="roadmap-container"><div id="roadmap-shell"></div></div>';
      });

      afterEach(() => {
        document.querySelector('.roadmap-container').remove();
      });

      it('returns style object based on shellWidth and current Window width with Scollbar size offset', (done) => {
        const vmWithParentEl = createComponent({}, document.getElementById('roadmap-shell'));
        Vue.nextTick(() => {
          const stylesObj = vmWithParentEl.containerStyles;
          // Ensure that value for `width` & `height`
          // is a non-zero number.
          expect(parseInt(stylesObj.width, 10) !== 0).toBe(true);
          expect(parseInt(stylesObj.height, 10) !== 0).toBe(true);
          vmWithParentEl.$destroy();
          done();
        });
      });
    });
  });

  describe('methods', () => {
    describe('getWidthOffset', () => {
      it('returns 0 when noScroll prop is true', () => {
        vm.noScroll = true;
        expect(vm.getWidthOffset()).toBe(0);
      });

      it('returns value of SCROLL_BAR_SIZE when noScroll prop is false', () => {
        vm.noScroll = false;
        expect(vm.getWidthOffset()).toBe(mockScrollBarSize);
      });
    });

    describe('handleScroll', () => {
      beforeEach(() => {
        spyOn(eventHub, '$emit');
      });

      it('emits `epicsListScrolled` event via eventHub when `noScroll` prop is false', () => {
        vm.noScroll = false;
        vm.handleScroll();
        expect(eventHub.$emit).toHaveBeenCalledWith('epicsListScrolled', jasmine.any(Object));
      });

      it('does not emit any event via eventHub when `noScroll` prop is true', () => {
        vm.noScroll = true;
        vm.handleScroll();
        expect(eventHub.$emit).not.toHaveBeenCalled();
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class `roadmap-shell`', () => {
      expect(vm.$el.classList.contains('roadmap-shell')).toBe(true);
    });

    it('adds `prevent-vertical-scroll` class on component container element', (done) => {
      vm.noScroll = true;
      Vue.nextTick(() => {
        expect(vm.$el.classList.contains('prevent-vertical-scroll')).toBe(true);
        done();
      });
    });
  });
});
