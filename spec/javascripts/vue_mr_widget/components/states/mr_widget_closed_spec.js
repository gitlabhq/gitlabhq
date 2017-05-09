import Vue from 'vue';
import closedComponent from '~/vue_merge_request_widget/components/states/mr_widget_closed';

const mr = {
  targetBranch: 'good-branch',
  targetBranchCommitsPath: '/good-branch',
  closedBy: {
    name: 'Fatih Acet',
    username: 'fatihacet',
  },
  updatedAt: '2017-03-23T20:08:08.845Z',
  closedAt: '1 day ago',
};

const createComponent = () => {
  const Component = Vue.extend(closedComponent);

  return new Component({
    el: document.createElement('div'),
    propsData: { mr },
  }).$el;
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
    it('should have correct elements', () => {
      const el = createComponent();

      expect(el.querySelector('h4').textContent).toContain('Closed by');
      expect(el.querySelector('h4').textContent).toContain(mr.closedBy.name);
      expect(el.textContent).toContain('The changes were not merged into');
      expect(el.querySelector('.label-branch').getAttribute('href')).toEqual(mr.targetBranchCommitsPath);
      expect(el.querySelector('.label-branch').textContent).toContain(mr.targetBranch);
    });
  });
});
