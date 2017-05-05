import Vue from 'vue';
import eventHub from '~/issuable/related_issues/event_hub';
import relatedIssuesBlock from '~/issuable/related_issues/components/related_issues_block.vue';

const issuable1 = {
  reference: 'foo/bar#123',
  displayReference: '#123',
  title: 'some title',
  path: '/foo/bar/issues/123',
  state: 'opened',
};

const issuable2 = {
  reference: 'foo/bar#124',
  displayReference: '#124',
  title: 'some other thing',
  path: '/foo/bar/issues/124',
  state: 'opened',
};

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
  });

  describe('with canAddRelatedIssues=true', () => {
    beforeEach(() => {
      vm = new RelatedIssuesBlock({
        propsData: {
          canAddRelatedIssues: true,
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
    let showAddRelatedIssuesFormSpy;

    beforeEach(() => {
      vm = new RelatedIssuesBlock({
        propsData: {
          relatedIssues: [
            issuable1,
          ],
        },
      }).$mount();
      showAddRelatedIssuesFormSpy = jasmine.createSpy('spy');
      eventHub.$on('showAddRelatedIssuesForm', showAddRelatedIssuesFormSpy);
    });

    afterEach(() => {
      eventHub.$off('showAddRelatedIssuesForm', showAddRelatedIssuesFormSpy);
    });

    it('when expanding add related issue form', () => {
      expect(showAddRelatedIssuesFormSpy).not.toHaveBeenCalled();
      vm.showAddRelatedIssuesForm();
      expect(showAddRelatedIssuesFormSpy).toHaveBeenCalled();
    });
  });
});
