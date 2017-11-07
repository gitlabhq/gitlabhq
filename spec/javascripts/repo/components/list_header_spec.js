import Vue from 'vue';
import store from '~/repo/stores';
import listHeader from '~/repo/components/list_header.vue';
import { resetStore } from '../helpers';

describe('Multi-file list header', () => {
  let vm;

  beforeEach(() => {
    const Comp = Vue.extend(listHeader);

    vm = new Comp({
      store,
    }).$mount();
  });

  afterEach(() => {
    resetStore(vm.$store);
  });

  describe('can commit', () => {
    beforeEach((done) => {
      vm.$store.state.canCommit = true;

      Vue.nextTick(done);
    });

    it('renders new entry buttons', () => {
      expect(vm.$el.querySelectorAll('.btn-transparent').length).toBe(2);
      expect(
        vm.$el.querySelectorAll('.btn-transparent')[0].getAttribute('aria-label'),
      ).toBe('Create new file');
      expect(
        vm.$el.querySelectorAll('.btn-transparent')[1].getAttribute('aria-label'),
      ).toBe('Create new directory');
    });

    it('opens new file modal after clicking new file button', () => {
      vm.$el.querySelectorAll('.btn-transparent')[0].click();

      expect(vm.$store.state.newEntryModalOpen).toBeTruthy();
      expect(vm.$store.state.newEntryModalType).toBe('blob');
    });

    it('opens new directory modal after clicking new directory button', () => {
      vm.$el.querySelectorAll('.btn-transparent')[1].click();

      expect(vm.$store.state.newEntryModalOpen).toBeTruthy();
      expect(vm.$store.state.newEntryModalType).toBe('tree');
    });
  });

  describe('can not commit', () => {
    beforeEach((done) => {
      vm.$store.state.canCommit = false;

      Vue.nextTick(done);
    });

    it('does not render new entry buttons', () => {
      expect(vm.$el.querySelectorAll('.btn-transparent').length).toBe(0);
    });
  });
});
