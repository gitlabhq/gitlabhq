import Vue from 'vue';

import epicItemComponent from 'ee/roadmap/components/epic_item.vue';

import { mockTimeframe, mockEpic, mockGroupId, mockShellWidth } from '../mock_data';

import mountComponent from '../../helpers/vue_mount_component_helper';

const createComponent = ({
  epic = mockEpic,
  timeframe = mockTimeframe,
  currentGroupId = mockGroupId,
  shellWidth = mockShellWidth,
}) => {
  const Component = Vue.extend(epicItemComponent);

  return mountComponent(Component, {
    epic,
    timeframe,
    currentGroupId,
    shellWidth,
  });
};

describe('EpicItemComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent({});
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('template', () => {
    it('renders component container element class `epics-list-item`', () => {
      expect(vm.$el.classList.contains('epics-list-item')).toBeTruthy();
    });

    it('renders Epic item details element with class `epic-details-cell`', () => {
      expect(vm.$el.querySelector('.epic-details-cell')).not.toBeNull();
    });

    it('renders Epic timeline element with class `epic-timeline-cell`', () => {
      expect(vm.$el.querySelector('.epic-timeline-cell')).not.toBeNull();
    });
  });
});
