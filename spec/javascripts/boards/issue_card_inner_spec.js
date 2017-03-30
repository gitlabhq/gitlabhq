import Vue from 'vue';
import cardComponent from '~/boards/components/issue_card_inner';
import headerComponent from '~/boards/components/issue_card_header';
import labelsComponent from '~/boards/components/issue_card_labels';

const propData = {
  issue: {
    title: 'title',
    id: 1,
    confidential: true,
    assignee: {},
    labels: [],
  },
  issueLinkBase: 'issueLinkBase',
  list: {},
  rootPath: 'rootPath',
  updateFilters: false,
};

const createComponent = (componentName, propsData) => {
  const Component = Vue.extend.call(Vue, componentName);

  return new Component({
    el: document.createElement('div'),
    propsData,
  });
};

describe('IssueCardInner', () => {
  describe('props', () => {
    const props = cardComponent.props;

    it('should have issue prop', () => {
      const { issue } = props;

      expect(issue).toBeDefined();
      expect(issue instanceof Object).toBeTruthy();
      expect(issue.required).toBeTruthy();
    });

    it('should have issueLinkBase prop', () => {
      const { issueLinkBase } = props;
      const IssueLinkBaseClass = issueLinkBase.type;

      expect(issueLinkBase).toBeDefined();
      expect(new IssueLinkBaseClass() instanceof String).toBeTruthy();
      expect(issueLinkBase.required).toBeTruthy();
    });

    it('should have list prop', () => {
      const { list } = props;

      expect(list).toBeDefined();
      expect(list instanceof Object).toBeTruthy();
      expect(list.required).toBeFalsy();
    });

    it('should have rootPath prop', () => {
      const { rootPath } = props;
      const RootPathClass = rootPath.type;

      expect(rootPath).toBeDefined();
      expect(new RootPathClass() instanceof String).toBeTruthy();
      expect(rootPath.required).toBeTruthy();
    });

    it('should have updateFilters prop', () => {
      const { updateFilters } = props;
      const UpdateFiltersClass = updateFilters.type;

      expect(updateFilters).toBeDefined();
      expect(new UpdateFiltersClass() instanceof Boolean).toBeTruthy();
      expect(updateFilters.required).toBeFalsy();
      expect(updateFilters.default).toBeFalsy();
    });
  });

  describe('computed', () => {
    describe('assignee', () => {
      it('should return assignee object by default', () => {
        const vm = createComponent(cardComponent, propData);
        expect(vm.assignee instanceof Object).toBeTruthy();
      });

      it('should return empty object if assignee is false', () => {
        const data = Object.assign({}, propData);
        data.issue.assignee = false;

        const vm = createComponent(cardComponent, data);
        expect(vm.assignee instanceof Object).toBeTruthy();
      });
    });
  });

  describe('components', () => {
    it('should have components added', () => {
      expect(cardComponent.components['issue-card-header']).toBeDefined();
      expect(cardComponent.components['issue-card-labels']).toBeDefined();
    });
  });

  describe('template', () => {
    it('should have correct elements', () => {
      const vm = createComponent(cardComponent, propData);
      const el = vm.$el;

      const headerComponentEl = createComponent(headerComponent, {
        confidential: propData.issue.confidential,
        title: propData.issue.title,
        issueId: propData.issue.id,
        assignee: vm.assignee,
        issueLinkBase: propData.issueLinkBase,
        rootPath: propData.rootPath,
      }).$el;

      const labelsComponentEl = createComponent(labelsComponent, {
        labels: propData.issue.labels,
        list: propData.list,
        updateFilters: propData.updateFilters,
      }).$el;

      const contents = `${headerComponentEl.innerHTML}${labelsComponentEl.innerHTML}`;
      expect(el.innerHTML.indexOf(contents) !== -1).toEqual(true);
    });
  });
});
