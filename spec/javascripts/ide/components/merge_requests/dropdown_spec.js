import Vue from 'vue';
import { createStore } from '~/ide/stores';
import Dropdown from '~/ide/components/merge_requests/dropdown.vue';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';
import { mergeRequests } from '../../mock_data';

describe('IDE merge requests dropdown', () => {
  const Component = Vue.extend(Dropdown);
  let vm;

  beforeEach(() => {
    const store = createStore();

    vm = createComponentWithStore(Component, store, { show: false }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('does not render tabs when show is false', () => {
    expect(vm.$el.querySelector('.nav-links')).toBe(null);
  });

  describe('when show is true', () => {
    beforeEach(done => {
      vm.show = true;
      vm.$store.state.mergeRequests.assigned.mergeRequests.push(mergeRequests[0]);

      vm.$nextTick(done);
    });

    it('renders tabs', () => {
      expect(vm.$el.querySelector('.nav-links')).not.toBe(null);
    });

    it('renders count for assigned & created data', () => {
      expect(vm.$el.querySelector('.nav-links a').textContent).toContain('Created by me');
      expect(vm.$el.querySelector('.nav-links a .badge').textContent).toContain('0');

      expect(vm.$el.querySelectorAll('.nav-links a')[1].textContent).toContain('Assigned to me');
      expect(
        vm.$el.querySelectorAll('.nav-links a')[1].querySelector('.badge').textContent,
      ).toContain('1');
    });
  });
});
