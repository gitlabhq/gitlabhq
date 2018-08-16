import Vue from 'vue';
import { getTimeago } from '~/lib/utils/datetime_utility';
import component from '~/jobs/components/erased_block.vue';
import mountComponent from '../helpers/vue_mount_component_helper';

describe('Erased block', () => {
  const Component = Vue.extend(component);
  let vm;

  const erasedAt = '2016-11-07T11:11:16.525Z';
  const timeago = getTimeago();
  const formatedDate = timeago.format(erasedAt);

  afterEach(() => {
    vm.$destroy();
  });

  describe('with job erased by user', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        erasedByUser: true,
        username: 'root',
        linkToUser: 'gitlab.com/root',
        erasedAt,
      });
    });

    it('renders username and link', () => {
      expect(vm.$el.querySelector('a').getAttribute('href')).toEqual('gitlab.com/root');

      expect(vm.$el.textContent).toContain('Job has been erased by');
      expect(vm.$el.textContent).toContain('root');
    });

    it('renders erasedAt', () => {
      expect(vm.$el.textContent).toContain(formatedDate);
    });
  });

  describe('with erased job', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        erasedByUser: false,
        erasedAt,
      });
    });

    it('renders username and link', () => {
      expect(vm.$el.textContent).toContain('Job has been erased');
    });

    it('renders erasedAt', () => {
      expect(vm.$el.textContent).toContain(formatedDate);
    });
  });
});
