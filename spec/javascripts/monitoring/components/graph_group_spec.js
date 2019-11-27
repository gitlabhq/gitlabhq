import { shallowMount, createLocalVue } from '@vue/test-utils';
import GraphGroup from '~/monitoring/components/graph_group.vue';

const localVue = createLocalVue();

describe('Graph group component', () => {
  let graphGroup;

  const findPrometheusGroup = () => graphGroup.find('.prometheus-graph-group');
  const findPrometheusPanel = () => graphGroup.find('.prometheus-panel');

  const createComponent = propsData => {
    graphGroup = shallowMount(localVue.extend(GraphGroup), {
      propsData,
      sync: false,
      localVue,
    });
  };

  afterEach(() => {
    graphGroup.destroy();
  });

  describe('When groups can be collapsed', () => {
    beforeEach(() => {
      createComponent({
        name: 'panel',
        collapseGroup: true,
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
      createComponent({
        name: 'panel',
        collapseGroup: true,
        showPanels: false,
      });
    });

    it('should not contain a prometheus-panel container when showPanels is false', () => {
      expect(findPrometheusPanel().exists()).toBe(false);
    });
  });

  describe('When collapseGroup prop is updated', () => {
    beforeEach(() => {
      createComponent({ name: 'panel', collapseGroup: false });
    });

    it('previously collapsed group should respond to the prop change', done => {
      expect(findPrometheusGroup().exists()).toBe(false);

      graphGroup.setProps({
        collapseGroup: true,
      });

      graphGroup.vm.$nextTick(() => {
        expect(findPrometheusGroup().exists()).toBe(true);
        done();
      });
    });
  });
});
