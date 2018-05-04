import Vue from 'vue';

import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import appComponent from 'ee/geo_nodes/components/app.vue';
import eventHub from 'ee/geo_nodes/event_hub';
import GeoNodesStore from 'ee/geo_nodes/store/geo_nodes_store';
import GeoNodesService from 'ee/geo_nodes/service/geo_nodes_service';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { NODE_ACTIONS } from 'ee/geo_nodes/constants';
import { PRIMARY_VERSION, NODE_DETAILS_PATH, mockNodes, mockNode, rawMockNodeDetails } from '../mock_data';

const createComponent = () => {
  const Component = Vue.extend(appComponent);
  const store = new GeoNodesStore(PRIMARY_VERSION.version, PRIMARY_VERSION.revision);
  const service = new GeoNodesService(NODE_DETAILS_PATH);

  return mountComponent(Component, {
    store,
    service,
    nodeActionsAllowed: true,
    nodeEditAllowed: true,
  });
};

describe('AppComponent', () => {
  let vm;
  let mock;
  let statusCode;
  let response;

  beforeEach(() => {
    statusCode = 200;
    response = mockNodes;

    mock = new MockAdapter(axios);

    document.body.innerHTML += '<div class="flash-container"></div>';
    mock.onGet(/(.*)\/geo_nodes$/).reply(() => [statusCode, response]);
    vm = createComponent();
  });

  afterEach(() => {
    document.querySelector('.flash-container').remove();
    vm.$destroy();
    mock.restore();
  });

  describe('data', () => {
    it('returns default data props', () => {
      expect(vm.isLoading).toBe(true);
      expect(vm.hasError).toBe(false);
      expect(vm.showModal).toBe(false);
      expect(vm.targetNode).toBeNull();
      expect(vm.targetNodeActionType).toBe('');
      expect(vm.modalKind).toBe('warning');
      expect(vm.modalMessage).toBe('');
      expect(vm.modalActionLabel).toBe('');
    });
  });

  describe('computed', () => {
    describe('nodes', () => {
      it('returns list of nodes from store', () => {
        expect(Array.isArray(vm.nodes)).toBeTruthy();
      });
    });
  });

  describe('methods', () => {
    describe('setNodeActionStatus', () => {
      it('sets `nodeActionActive` property with value of `status` parameter for provided `node` parameter', () => {
        const node = {
          nodeActionActive: false,
        };
        vm.setNodeActionStatus(node, true);
        expect(node.nodeActionActive).toBe(true);
      });
    });

    describe('initNodeDetailsPolling', () => {
      it('initializes SmartInterval and sets it to component', () => {
        vm.initNodeDetailsPolling(2);
        expect(vm.nodePollingInterval).toBeDefined();
      });
    });

    describe('fetchGeoNodes', () => {
      it('calls service.getGeoNodes and sets response to the store on success', (done) => {
        spyOn(vm.store, 'setNodes');

        vm.fetchGeoNodes();
        setTimeout(() => {
          expect(vm.store.setNodes).toHaveBeenCalledWith(mockNodes);
          expect(vm.isLoading).toBe(false);
          done();
        }, 0);
      });

      it('sets error flag and message on failure', (done) => {
        response = 'Something went wrong';
        statusCode = 500;

        vm.fetchGeoNodes();
        setTimeout(() => {
          expect(vm.isLoading).toBe(false);
          expect(document.querySelector('.flash-text').innerText.trim()).toBe('Something went wrong while fetching nodes');
          done();
        }, 0);
      });
    });

    describe('fetchNodeDetails', () => {
      it('calls service.getGeoNodeDetails and sets response to the store on success', (done) => {
        mock.onGet(mockNode.statusPath).reply(200, rawMockNodeDetails);
        spyOn(vm.service, 'getGeoNodeDetails').and.callThrough();

        vm.fetchNodeDetails(mockNode);
        setTimeout(() => {
          expect(vm.service.getGeoNodeDetails).toHaveBeenCalled();
          expect(Object.keys(vm.store.state.nodeDetails).length).not.toBe(0);
          expect(vm.store.state.nodeDetails['1']).toBeDefined();
          done();
        }, 0);
      });

      it('emits `nodeDetailsLoaded` event with fake nodeDetails object on 404 failure', (done) => {
        spyOn(eventHub, '$emit');
        mock.onGet(mockNode.statusPath).reply(404, {});
        spyOn(vm.service, 'getGeoNodeDetails').and.callThrough();

        vm.fetchNodeDetails(mockNode);
        setTimeout(() => {
          expect(eventHub.$emit).toHaveBeenCalledWith('nodeDetailsLoaded', jasmine.any(Object));
          const nodeDetails = vm.store.state.nodeDetails['1'];
          expect(nodeDetails).toBeDefined();
          expect(nodeDetails.syncStatusUnavailable).toBe(true);
          expect(nodeDetails.health).toBe('Request failed with status code 404');
          done();
        }, 0);
      });

      it('emits `nodeDetailsLoaded` event with fake nodeDetails object on 500 failure', (done) => {
        spyOn(eventHub, '$emit');
        mock.onGet(mockNode.statusPath).reply(500, {});
        spyOn(vm.service, 'getGeoNodeDetails').and.callThrough();

        vm.fetchNodeDetails(mockNode);
        setTimeout(() => {
          expect(eventHub.$emit).toHaveBeenCalledWith('nodeDetailsLoaded', jasmine.any(Object));
          const nodeDetails = vm.store.state.nodeDetails['1'];
          expect(nodeDetails).toBeDefined();
          expect(nodeDetails.syncStatusUnavailable).toBe(true);
          expect(nodeDetails.health).toBe('Request failed with status code 500');
          done();
        }, 0);
      });

      it('emits `nodeDetailsLoadFailed` event on failure when there is no response', (done) => {
        spyOn(eventHub, '$emit');
        mock.onGet(mockNode.statusPath).reply(500, null);
        spyOn(vm.service, 'getGeoNodeDetails').and.callThrough();

        vm.fetchNodeDetails(mockNode);
        setTimeout(() => {
          expect(eventHub.$emit).toHaveBeenCalledWith('nodeDetailsLoadFailed', mockNode.id, jasmine.any(Object));
          done();
        }, 0);
      });
    });

    describe('repairNode', () => {
      it('calls service.repairNode and shows success Flash message on request success', (done) => {
        const node = { ...mockNode };
        mock.onPost(node.repairPath).reply(200);
        spyOn(vm.service, 'repairNode').and.callThrough();

        vm.repairNode(node);
        expect(node.nodeActionActive).toBe(true);
        setTimeout(() => {
          expect(vm.service.repairNode).toHaveBeenCalledWith(node);
          expect(document.querySelector('.flash-text').innerText.trim()).toBe('Node Authentication was successfully repaired.');
          expect(node.nodeActionActive).toBe(false);
          done();
        });
      });

      it('calls service.repairNode and shows failure Flash message on request failure', (done) => {
        const node = { ...mockNode };
        mock.onPost(node.repairPath).reply(500);
        spyOn(vm.service, 'repairNode').and.callThrough();

        vm.repairNode(node);
        setTimeout(() => {
          expect(vm.service.repairNode).toHaveBeenCalledWith(node);
          expect(document.querySelector('.flash-text').innerText.trim()).toBe('Something went wrong while repairing node');
          expect(node.nodeActionActive).toBe(false);
          done();
        });
      });
    });

    describe('toggleNode', () => {
      it('calls service.toggleNode for enabling node and updates toggle button on request success', (done) => {
        const node = { ...mockNode };
        mock.onPut(node.basePath).reply(200, {
          enabled: true,
        });
        spyOn(vm.service, 'toggleNode').and.callThrough();
        node.enabled = false;

        vm.toggleNode(node);
        expect(node.nodeActionActive).toBe(true);
        setTimeout(() => {
          expect(vm.service.toggleNode).toHaveBeenCalledWith(node);
          expect(node.enabled).toBe(true);
          expect(node.nodeActionActive).toBe(false);
          done();
        });
      });

      it('calls service.toggleNode and shows Flash error on request failure', (done) => {
        const node = { ...mockNode };
        mock.onPut(node.basePath).reply(500);
        spyOn(vm.service, 'toggleNode').and.callThrough();
        node.enabled = false;

        vm.toggleNode(node);
        expect(node.nodeActionActive).toBe(true);
        setTimeout(() => {
          expect(vm.service.toggleNode).toHaveBeenCalledWith(node);
          expect(document.querySelector('.flash-text').innerText.trim()).toBe('Something went wrong while changing node status');
          expect(node.nodeActionActive).toBe(false);
          done();
        });
      });
    });

    describe('removeNode', () => {
      it('calls service.removeNode for removing node and shows Flash message on request success', (done) => {
        const node = { ...mockNode };
        mock.onDelete(node.basePath).reply(200);
        spyOn(vm.service, 'removeNode').and.callThrough();
        spyOn(vm.store, 'removeNode').and.stub();

        vm.removeNode(node);
        expect(node.nodeActionActive).toBe(true);
        setTimeout(() => {
          expect(vm.service.removeNode).toHaveBeenCalledWith(node);
          expect(vm.store.removeNode).toHaveBeenCalledWith(node);
          expect(document.querySelector('.flash-text').innerText.trim()).toBe('Node was successfully removed.');
          done();
        });
      });

      it('calls service.removeNode and shows Flash message on request failure', (done) => {
        const node = { ...mockNode };
        mock.onDelete(node.basePath).reply(500);
        spyOn(vm.service, 'removeNode').and.callThrough();
        spyOn(vm.store, 'removeNode').and.stub();

        vm.removeNode(node);
        expect(node.nodeActionActive).toBe(true);
        setTimeout(() => {
          expect(vm.service.removeNode).toHaveBeenCalledWith(node);
          expect(vm.store.removeNode).not.toHaveBeenCalled();
          expect(document.querySelector('.flash-text').innerText.trim()).toBe('Something went wrong while removing node');
          done();
        });
      });
    });

    describe('handleNodeAction', () => {
      it('sets `showModal` to false and calls `toggleNode` when `targetNodeActionType` is `toggle`', () => {
        vm.targetNode = { ...mockNode };
        vm.targetNodeActionType = NODE_ACTIONS.TOGGLE;
        vm.showModal = true;
        spyOn(vm, 'toggleNode').and.stub();

        vm.handleNodeAction();
        expect(vm.showModal).toBe(false);
        expect(vm.toggleNode).toHaveBeenCalledWith(vm.targetNode);
      });

      it('sets `showModal` to false and calls `removeNode` when `targetNodeActionType` is `remove`', () => {
        vm.targetNode = { ...mockNode };
        vm.targetNodeActionType = NODE_ACTIONS.REMOVE;
        vm.showModal = true;
        spyOn(vm, 'removeNode').and.stub();

        vm.handleNodeAction();
        expect(vm.showModal).toBe(false);
        expect(vm.removeNode).toHaveBeenCalledWith(vm.targetNode);
      });
    });

    describe('showNodeActionModal', () => {
      let node;
      let modalKind;
      let modalMessage;
      let modalActionLabel;

      beforeEach(() => {
        node = { ...mockNode };
        modalKind = 'warning';
        modalMessage = 'Foobar message';
        modalActionLabel = 'Disable';
      });

      it('sets target node and modal config props on component', () => {
        vm.showNodeActionModal({
          actionType: NODE_ACTIONS.TOGGLE,
          node,
          modalKind,
          modalMessage,
          modalActionLabel,
        });
        expect(vm.targetNode).toBe(node);
        expect(vm.targetNodeActionType).toBe(NODE_ACTIONS.TOGGLE);
        expect(vm.modalKind).toBe(modalKind);
        expect(vm.modalMessage).toBe(modalMessage);
        expect(vm.modalActionLabel).toBe(modalActionLabel);
      });

      it('sets showModal to `true` when actionType is `toggle` and node is enabled', () => {
        node.enabled = true;
        vm.showNodeActionModal({
          actionType: NODE_ACTIONS.TOGGLE,
          node,
          modalKind,
          modalMessage,
          modalActionLabel,
        });
        expect(vm.showModal).toBe(true);
      });

      it('calls toggleNode when actionType is `toggle` and node.enabled is `false`', () => {
        node.enabled = false;
        spyOn(vm, 'toggleNode').and.stub();

        vm.showNodeActionModal({
          actionType: NODE_ACTIONS.TOGGLE,
          node,
          modalKind,
          modalMessage,
          modalActionLabel,
        });
        expect(vm.toggleNode).toHaveBeenCalledWith(vm.targetNode);
      });

      it('sets showModal to `true` when actionType is not `toggle`', () => {
        node.enabled = true;
        vm.showNodeActionModal({
          actionType: NODE_ACTIONS.REMOVE,
          node,
          modalKind,
          modalMessage,
          modalActionLabel,
        });
        expect(vm.showModal).toBe(true);
      });
    });

    describe('hideNodeActionModal', () => {
      it('sets `showModal` to `false`', () => {
        vm.showModal = true;
        vm.hideNodeActionModal();
        expect(vm.showModal).toBe(false);
      });
    });
  });

  describe('created', () => {
    it('binds event handler for `pollNodeDetails`', () => {
      spyOn(eventHub, '$on');
      const vmX = createComponent();
      expect(eventHub.$on).toHaveBeenCalledWith('pollNodeDetails', jasmine.any(Function));
      expect(eventHub.$on).toHaveBeenCalledWith('showNodeActionModal', jasmine.any(Function));
      expect(eventHub.$on).toHaveBeenCalledWith('repairNode', jasmine.any(Function));
      vmX.$destroy();
    });
  });

  describe('beforeDestroy', () => {
    it('unbinds event handler for `pollNodeDetails`', () => {
      spyOn(eventHub, '$off');
      const vmX = createComponent();
      vmX.$destroy();
      expect(eventHub.$off).toHaveBeenCalledWith('pollNodeDetails', jasmine.any(Function));
      expect(eventHub.$off).toHaveBeenCalledWith('showNodeActionModal', jasmine.any(Function));
      expect(eventHub.$off).toHaveBeenCalledWith('repairNode', jasmine.any(Function));
    });
  });

  describe('template', () => {
    it('renders container element with class `geo-nodes-container`', () => {
      expect(vm.$el.classList.contains('geo-nodes-container')).toBe(true);
    });

    it('renders loading animation when `isLoading` is true', () => {
      vm.isLoading = true;
      expect(vm.$el.querySelectorAll('.loading-animation.prepend-top-20.append-bottom-20').length).not.toBe(0);
    });
  });
});
