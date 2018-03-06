import Vue from 'vue';
import eventHub from 'ee/related_issues/event_hub';
import relatedIssuesBlock from 'ee/related_issues/components/related_issues_block.vue';

import { issuable1, issuable2, issuable3, issuable4, issuable5 } from '../mock_data';

describe('RelatedIssuesBlock', () => {
  let RelatedIssuesBlock;
  let vm;

  beforeEach(() => {
    RelatedIssuesBlock = Vue.extend(relatedIssuesBlock);
  });

  afterEach(() => {
    if (vm) {
      vm.$destroy();
    }
  });

  describe('with defaults', () => {
    beforeEach(() => {
      vm = new RelatedIssuesBlock().$mount();
    });

    it('unable to add new related issues', () => {
      expect(vm.$refs.issueCountBadgeAddButton).toBeUndefined();
    });

    it('add related issues form is hidden', () => {
      expect(vm.$el.querySelector('.js-add-related-issues-form-area')).toBeNull();
    });

    it('should not show loading icon', () => {
      expect(vm.$refs.loadingIcon).toBeUndefined();
    });
  });

  describe('with isFetching=true', () => {
    beforeEach(() => {
      vm = new RelatedIssuesBlock({
        propsData: {
          isFetching: true,
        },
      }).$mount();
    });

    it('should show loading icon', () => {
      expect(vm.$refs.loadingIcon).toBeDefined();
    });

    it('should show `...` badge count', () => {
      expect(vm.badgeLabel).toBe('...');
    });
  });

  describe('with canAddRelatedIssues=true', () => {
    beforeEach(() => {
      vm = new RelatedIssuesBlock({
        propsData: {
          canAdmin: true,
        },
      }).$mount();
    });

    it('can add new related issues', () => {
      expect(vm.$refs.issueCountBadgeAddButton).toBeDefined();
    });
  });

  describe('with isFormVisible=true', () => {
    beforeEach(() => {
      vm = new RelatedIssuesBlock({
        propsData: {
          isFormVisible: true,
        },
      }).$mount();
    });

    it('shows add related issues form', () => {
      expect(vm.$el.querySelector('.js-add-related-issues-form-area')).toBeDefined();
    });
  });

  describe('with relatedIssues', () => {
    beforeEach(() => {
      vm = new RelatedIssuesBlock({
        propsData: {
          relatedIssues: [
            issuable1,
            issuable2,
          ],
        },
      }).$mount();
    });

    it('should render issue tokens items', () => {
      expect(vm.$el.querySelectorAll('.js-related-issues-token-list-item').length).toEqual(2);
    });
  });

  describe('methods', () => {
    let toggleAddRelatedIssuesFormSpy;

    beforeEach(() => {
      vm = new RelatedIssuesBlock({
        propsData: {
          relatedIssues: [
            issuable1,
            issuable2,
            issuable3,
            issuable4,
            issuable5,
          ],
        },
      }).$mount();
      toggleAddRelatedIssuesFormSpy = jasmine.createSpy('spy');
      eventHub.$on('toggleAddRelatedIssuesForm', toggleAddRelatedIssuesFormSpy);
    });

    afterEach(() => {
      eventHub.$off('toggleAddRelatedIssuesForm', toggleAddRelatedIssuesFormSpy);
    });

    it('reorder item correctly when an item is moved to the top', () => {
      const beforeAfterIds = vm.getBeforeAfterId(vm.$el.querySelector('ul li:first-child'));
      expect(beforeAfterIds.beforeId).toBeNull();
      expect(beforeAfterIds.afterId).toBe(2);
    });

    it('reorder item correctly when an item is moved to the bottom', () => {
      const beforeAfterIds = vm.getBeforeAfterId(vm.$el.querySelector('ul li:last-child'));
      expect(beforeAfterIds.beforeId).toBe(4);
      expect(beforeAfterIds.afterId).toBeNull();
    });

    it('reorder item correctly when an item is swapped with adjecent item', () => {
      const beforeAfterIds = vm.getBeforeAfterId(vm.$el.querySelector('ul li:nth-child(3)'));
      expect(beforeAfterIds.beforeId).toBe(2);
      expect(beforeAfterIds.afterId).toBe(4);
    });

    it('reorder item correctly when an item is moved somewhere in the middle', () => {
      const beforeAfterIds = vm.getBeforeAfterId(vm.$el.querySelector('ul li:nth-child(4)'));
      expect(beforeAfterIds.beforeId).toBe(3);
      expect(beforeAfterIds.afterId).toBe(5);
    });

    it('when expanding add related issue form', () => {
      expect(toggleAddRelatedIssuesFormSpy).not.toHaveBeenCalled();
      vm.toggleAddRelatedIssuesForm();
      expect(toggleAddRelatedIssuesFormSpy).toHaveBeenCalled();
    });
  });
});
