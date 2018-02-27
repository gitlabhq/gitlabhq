import Vue from 'vue';

import roadmapShellComponent from 'ee/roadmap/components/roadmap_shell.vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockEpic, mockTimeframe, mockGroupId } from '../mock_data';

const createComponent = ({
  epics = [mockEpic],
  timeframe = mockTimeframe,
  currentGroupId = mockGroupId,
}) => {
  const Component = Vue.extend(roadmapShellComponent);

  return mountComponent(Component, {
    epics,
    timeframe,
    currentGroupId,
  });
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
    });
  });

  describe('tableStyles', () => {
    it('returns style string based on shellWidth and Scollbar size', () => {
      // Since shellWidth is initialized on component mount
      // from parentElement.clientWidth, it will always be Zero
      // as parentElement is not available during tests.
      // so end result is 0 - scrollbar_size = -15
      expect(vm.tableStyles).toBe('width: -15px;');
    });
  });

  describe('template', () => {
    it('renders component container element with class `roadmap-shell`', () => {
      expect(vm.$el.classList.contains('roadmap-shell')).toBeTruthy();
    });
  });
});
