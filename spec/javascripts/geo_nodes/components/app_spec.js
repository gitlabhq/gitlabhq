import Vue from 'vue';

import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import appComponent from 'ee/geo_nodes/components/app.vue';
import eventHub from 'ee/geo_nodes/event_hub';
import GeoNodesStore from 'ee/geo_nodes/store/geo_nodes_store';
import GeoNodesService from 'ee/geo_nodes/service/geo_nodes_service';
import { PRIMARY_VERSION, NODE_DETAILS_PATH, mockNodes, rawMockNodeDetails } from '../mock_data';

import mountComponent from '../../helpers/vue_mount_component_helper';

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

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      expect(vm.isLoading).toBeTruthy();
      expect(vm.hasError).toBeFalsy();
      expect(vm.errorMessage).toBe('');
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
    describe('fetchGeoNodes', () => {
      it('calls service.getGeoNodes and sets response to the store on success', (done) => {
        const mock = new MockAdapter(axios);
        mock.onGet(vm.store.geoNodesPath).reply(200, mockNodes);
        spyOn(vm.store, 'setNodes');

        vm.fetchGeoNodes();
        expect(vm.hasError).toBeFalsy();
        setTimeout(() => {
          expect(vm.store.setNodes).toHaveBeenCalledWith(mockNodes);
          expect(vm.isLoading).toBeFalsy();
          done();
        }, 0);
      });

      it('sets error flag and message on failure', (done) => {
        const err = 'Something went wrong';
        const mock = new MockAdapter(axios);
        mock.onGet(vm.store.geoNodesPath).reply(500, err);

        vm.fetchGeoNodes();
        expect(vm.hasError).toBeFalsy();
        setTimeout(() => {
          expect(vm.hasError).toBeTruthy();
          expect(vm.errorMessage.response.data).toBe(err);
          done();
        }, 0);
      });
    });

    describe('fetchNodeDetails', () => {
      it('calls service.getGeoNodeDetails and sets response to the store on success', (done) => {
        const mock = new MockAdapter(axios);
        mock.onGet(`${vm.service.geoNodeDetailsBasePath}/2/status.json`).reply(200, rawMockNodeDetails);
        spyOn(vm.store, 'setNodeDetails');

        vm.fetchNodeDetails(2);
        setTimeout(() => {
          expect(vm.store.setNodeDetails).toHaveBeenCalled();
          done();
        }, 0);
      });

      it('emits `nodeDetailsLoadFailed` event on failure', (done) => {
        const err = 'Something went wrong';
        const mock = new MockAdapter(axios);
        spyOn(eventHub, '$emit');
        mock.onGet(`${vm.service.geoNodeDetailsBasePath}/2/status.json`).reply(500, err);

        vm.fetchNodeDetails(2);
        setTimeout(() => {
          expect(eventHub.$emit).toHaveBeenCalledWith('nodeDetailsLoadFailed', 2, jasmine.any(Object));
          done();
        }, 0);
      });
    });

    describe('initNodeDetailsPolling', () => {
      it('initializes SmartInterval and sets it to component', () => {
        vm.initNodeDetailsPolling(2);
        expect(vm.nodePollingInterval).toBeDefined();
      });
    });
  });

  describe('created', () => {
    it('binds event handler for `pollNodeDetails`', () => {
      spyOn(eventHub, '$on');
      const vmX = createComponent();
      expect(eventHub.$on).toHaveBeenCalledWith('pollNodeDetails', jasmine.any(Function));
      vmX.$destroy();
    });
  });

  describe('beforeDestroy', () => {
    it('unbinds event handler for `pollNodeDetails`', () => {
      spyOn(eventHub, '$off');
      const vmX = createComponent();
      vmX.$destroy();
      expect(eventHub.$off).toHaveBeenCalledWith('pollNodeDetails', jasmine.any(Function));
    });
  });

  describe('template', () => {
    it('renders container elements correctly', () => {
      expect(vm.$el.classList.contains('panel', 'panel-default')).toBeTruthy();
      expect(vm.$el.querySelectorAll('.panel-heading').length).not.toBe(0);
      expect(vm.$el.querySelector('.panel-heading').innerText.trim()).toBe('Geo nodes (0)');
    });

    it('renders loading animation when `isLoading` is true', () => {
      vm.isLoading = true;
      expect(vm.$el.querySelectorAll('.loading-animation.prepend-top-20.append-bottom-20').length).not.toBe(0);
    });

    it('renders list of nodes', (done) => {
      vm.store.setNodes(mockNodes);
      vm.isLoading = false;

      Vue.nextTick(() => {
        expect(vm.$el.querySelectorAll('.loading-animation.prepend-top-20.append-bottom-20').length).toBe(0);
        expect(vm.$el.querySelectorAll('ul.geo-nodes').length).not.toBe(0);
        done();
      });
    });

    it('renders error message', (done) => {
      vm.hasError = true;
      vm.isLoading = false;
      vm.errorMessage = 'Something went wrong.';

      Vue.nextTick(() => {
        const errEl = 'p.health-message.prepend-left-15.append-right-15';
        expect(vm.$el.querySelectorAll(errEl).length).not.toBe(0);
        expect(vm.$el.querySelector(errEl).innerText.trim()).toBe(vm.errorMessage);
        done();
      });
    });
  });
});
