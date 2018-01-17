import Vue from 'vue';

import geoNodeEventStatusComponent from 'ee/geo_nodes/components/geo_node_event_status.vue';
import { mockNodeDetails } from '../mock_data';

import mountComponent from '../../helpers/vue_mount_component_helper';

const createComponent = () => {
  const Component = Vue.extend(geoNodeEventStatusComponent);

  return mountComponent(Component, {
    eventId: mockNodeDetails.lastEvent.id,
    eventTimeStamp: mockNodeDetails.lastEvent.timeStamp,
  });
};

describe('GeoNodeEventStatus', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
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
  });

  describe('template', () => {
    it('renders container elements correctly', () => {
      expect(vm.$el.classList.contains('node-detail-value')).toBeTruthy();
      expect(vm.$el.querySelectorAll('strong').length).not.toBe(0);
      expect(vm.$el.querySelector('strong').innerText.trim()).toBe(`${mockNodeDetails.lastEvent.id}`);
      expect(vm.$el.querySelector('.event-status-timestamp').innerText).toContain('ago');
    });
  });
});
