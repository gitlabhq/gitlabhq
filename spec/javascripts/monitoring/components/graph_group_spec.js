import { shallowMount } from '@vue/test-utils';
import GraphGroup from '~/monitoring/components/graph_group.vue';

describe('Graph group component', () => {
  let graphGroup;

  afterEach(() => {
    graphGroup.destroy();
  });

  describe('When groups can be collapsed', () => {
    beforeEach(() => {
      graphGroup = shallowMount(GraphGroup, {
        propsData: {
          name: 'panel',
          collapseGroup: true,
        },
      });
    });

    it('should show the angle-down caret icon when collapseGroup is true', () => {
      expect(graphGroup.vm.caretIcon).toBe('angle-down');
    });

    it('should show the angle-right caret icon when collapseGroup is false', () => {
      graphGroup.vm.collapse();

      expect(graphGroup.vm.caretIcon).toBe('angle-right');
    });
  });

  describe('When groups can not be collapsed', () => {
    beforeEach(() => {
      graphGroup = shallowMount(GraphGroup, {
        propsData: {
          name: 'panel',
          collapseGroup: true,
          showPanels: false,
        },
      });
    });

    it('should not contain a prometheus-graph-group container when showPanels is false', () => {
      expect(graphGroup.vm.$el.querySelector('.prometheus-graph-group')).toBe(null);
    });
  });
});
