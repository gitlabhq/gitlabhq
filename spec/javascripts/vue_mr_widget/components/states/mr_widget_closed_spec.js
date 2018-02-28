import Vue from 'vue';
import closedComponent from '~/vue_merge_request_widget/components/states/mr_widget_closed';

const mr = {
  targetBranch: 'good-branch',
  targetBranchPath: '/good-branch',
  metrics: {
    mergedBy: {},
    mergedAt: 'mergedUpdatedAt',
    closedBy: {
      name: 'Fatih Acet',
      username: 'fatihacet',
    },
    closedAt: 'closedEventUpdatedAt',
    readableMergedAt: '',
    readableClosedAt: '',
  },
  updatedAt: 'mrUpdatedAt',
  closedAt: '1 day ago',
};

const createComponent = () => {
  const Component = Vue.extend(closedComponent);

  return new Component({
    el: document.createElement('div'),
    propsData: { mr },
  });
};

describe('MRWidgetClosed', () => {
  describe('props', () => {
    it('should have props', () => {
      const mrProp = closedComponent.props.mr;

      expect(mrProp.type instanceof Object).toBeTruthy();
      expect(mrProp.required).toBeTruthy();
    });
  });

  describe('components', () => {
    it('should have components added', () => {
      expect(closedComponent.components['mr-widget-author-and-time']).toBeDefined();
    });
  });

  describe('template', () => {
    let vm;
    let el;

    beforeEach(() => {
      vm = createComponent();
      el = vm.$el;
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('should have correct elements', () => {
      expect(el.querySelector('h4').textContent).toContain('Closed by');
      expect(el.querySelector('h4').textContent).toContain(mr.metrics.closedBy.name);
      expect(el.textContent).toContain('The changes were not merged into');
      expect(el.querySelector('.label-branch').getAttribute('href')).toEqual(mr.targetBranchPath);
      expect(el.querySelector('.label-branch').textContent).toContain(mr.targetBranch);
    });

    it('should use closedEvent updatedAt as tooltip title', () => {
      expect(
        el.querySelector('time').getAttribute('title'),
      ).toBe('closedEventUpdatedAt');
    });
  });
});
