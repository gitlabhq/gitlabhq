import Vue from 'vue';

import geoNodeEventStatusComponent from 'ee/geo_nodes/components/geo_node_event_status.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockNodeDetails } from '../mock_data';

const createComponent = ({
  eventId = mockNodeDetails.lastEvent.id,
  eventTimeStamp = mockNodeDetails.lastEvent.timeStamp,
  eventTypeLogStatus = false,
}) => {
  const Component = Vue.extend(geoNodeEventStatusComponent);

  return mountComponent(Component, {
    eventId,
    eventTimeStamp,
    eventTypeLogStatus,
  });
};

describe('GeoNodeEventStatus', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent({});
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('timeStamp', () => {
      it('returns timestamp Date object', () => {
        expect(vm.timeStamp instanceof Date).toBeTruthy();
      });
    });

    describe('timeStampString', () => {
      it('returns formatted timestamp string', () => {
        expect(vm.timeStampString).toContain('Nov 21, 2017');
      });
    });

    describe('eventString', () => {
      it('returns computed event string when `eventTypeLogStatus` prop is true', () => {
        const vmWithLogStatus = createComponent({ eventTypeLogStatus: true });
        expect(vmWithLogStatus.eventString).toBe(`${mockNodeDetails.lastEvent.id} events behind`);
        vmWithLogStatus.$destroy();
      });

      it('returns event ID as it is when `eventTypeLogStatus` prop is false', () => {
        expect(vm.eventString).toBe(mockNodeDetails.lastEvent.id);
      });
    });
  });

  describe('template', () => {
    it('renders container elements correctly', () => {
      expect(vm.$el.classList.contains('node-detail-value')).toBeTruthy();
      expect(vm.$el.querySelectorAll('strong').length).not.toBe(0);
      expect(vm.$el.querySelector('strong').innerText.trim()).toBe(`${mockNodeDetails.lastEvent.id}`);
      expect(vm.$el.querySelector('.event-status-timestamp').innerText).toContain('ago');
    });

    it('renders empty state when timestamp is not present', () => {
      const vmWithoutTimestamp = createComponent({
        eventId: 0,
        eventTimeStamp: 0,
      });
      expect(vmWithoutTimestamp.$el.querySelectorAll('strong').length).not.toBe(0);
      expect(vmWithoutTimestamp.$el.querySelectorAll('.event-status-timestamp').length).toBe(0);
      expect(vmWithoutTimestamp.$el.querySelector('strong').innerText.trim()).toBe('Not available');
      vmWithoutTimestamp.$destroy();
    });
  });
});
