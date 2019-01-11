import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import ErrorTrackingList from '~/error_tracking/components/error_tracking_list.vue';
import { GlButton, GlEmptyState, GlLoadingIcon, GlTable } from '@gitlab/ui';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ErrorTrackingList', () => {
  let store;
  let wrapper;

  function mountComponent({ errorTrackingEnabled = true } = {}) {
    wrapper = shallowMount(ErrorTrackingList, {
      localVue,
      store,
      propsData: {
        indexPath: '/path',
        enableErrorTrackingLink: '/link',
        errorTrackingEnabled,
        illustrationPath: 'illustration/path',
      },
    });
  }

  beforeEach(() => {
    const actions = {
      getErrorList: () => {},
    };

    const state = {
      errors: [],
      loading: true,
    };

    store = new Vuex.Store({
      actions,
      state,
    });
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('loading', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('shows spinner', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBeTruthy();
      expect(wrapper.find(GlTable).exists()).toBeFalsy();
      expect(wrapper.find(GlButton).exists()).toBeFalsy();
    });
  });

  describe('results', () => {
    beforeEach(() => {
      store.state.loading = false;

      mountComponent();
    });

    it('shows table', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBeFalsy();
      expect(wrapper.find(GlTable).exists()).toBeTruthy();
      expect(wrapper.find(GlButton).exists()).toBeTruthy();
    });
  });

  describe('no results', () => {
    beforeEach(() => {
      store.state.loading = false;

      mountComponent();
    });

    it('shows empty table', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBeFalsy();
      expect(wrapper.find(GlTable).exists()).toBeTruthy();
      expect(wrapper.find(GlButton).exists()).toBeTruthy();
    });
  });

  describe('error tracking feature disabled', () => {
    beforeEach(() => {
      mountComponent({ errorTrackingEnabled: false });
    });

    it('shows empty state', () => {
      expect(wrapper.find(GlEmptyState).exists()).toBeTruthy();
      expect(wrapper.find(GlLoadingIcon).exists()).toBeFalsy();
      expect(wrapper.find(GlTable).exists()).toBeFalsy();
      expect(wrapper.find(GlButton).exists()).toBeFalsy();
    });
  });
});
