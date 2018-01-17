import GeoNodesStore from 'ee/geo_nodes/store/geo_nodes_store';

import { mockNodes, rawMockNodeDetails, mockNodeDetails } from '../mock_data';

describe('GeoNodesStore', () => {
  let store;

  beforeEach(() => {
    store = new GeoNodesStore(mockNodeDetails.primaryVersion, mockNodeDetails.primaryRevision);
  });

  describe('constructor', () => {
    it('initializes default state', () => {
      expect(typeof store.state).toBe('object');
      expect(Array.isArray(store.state.nodes)).toBeTruthy();
      expect(typeof store.state.nodeDetails).toBe('object');
      expect(store.state.primaryVersion).toBe(mockNodeDetails.primaryVersion);
      expect(store.state.primaryRevision).toBe(mockNodeDetails.primaryRevision);
    });
  });

  describe('setNodes', () => {
    it('sets nodes list to state', () => {
      store.setNodes(mockNodes);
      expect(store.getNodes()).toBe(mockNodes);
    });
  });

  describe('setNodeDetails', () => {
    it('sets node details to state', () => {
      store.setNodeDetails(2, rawMockNodeDetails);
      expect(typeof store.getNodeDetails(2)).toBe('object');
    });
  });

  describe('formatNodeDetails', () => {
    it('returns formatted raw node details object', () => {
      const nodeDetails = GeoNodesStore.formatNodeDetails(rawMockNodeDetails);
      expect(nodeDetails.healthStatus).toBe(rawMockNodeDetails.health_status);
      expect(nodeDetails.replicationSlotWAL)
        .toBe(rawMockNodeDetails.replication_slots_max_retained_wal_bytes);
    });
  });
});
