import Vue from 'vue';
import eventHub from '~/issuable/related_issues/event_hub';
import RelatedIssuesService from '~/issuable/related_issues/services/related_issues_service';
import issueToken from '~/issuable/related_issues/components/issue_token.vue';

describe('IssueToken', () => {
  const reference = 'foo/bar#123';
  const title = 'some title';
  let IssueToken;
  let vm;

  beforeEach(() => {
    IssueToken = Vue.extend(issueToken);
  });

  afterEach(() => {
    if (vm) {
      vm.$destroy();
    }
  });

  describe('with reference supplied', () => {
    beforeEach(() => {
      vm = new IssueToken({
        propsData: {
          reference,
        },
      }).$mount();
    });

    it('shows reference', () => {
      expect(vm.$el.textContent.trim()).toEqual(reference);
    });
  });

  describe('with reference and title supplied', () => {
    beforeEach(() => {
      vm = new IssueToken({
        propsData: {
          reference,
          title,
        },
      }).$mount();
    });

    it('shows reference and title', () => {
      expect(vm.$refs.reference.textContent.trim()).toEqual(reference);
      expect(vm.$refs.title.textContent.trim()).toEqual(title);
    });
  });

  describe('with path supplied', () => {
    const path = '/foo/bar/issues/123';
    beforeEach(() => {
      vm = new IssueToken({
        propsData: {
          reference,
          title,
          path,
        },
      }).$mount();
    });

    it('links reference and title', () => {
      expect(vm.$refs.link.getAttribute('href')).toEqual(path);
    });
  });

  describe('with state supplied', () => {
    describe('`state: \'opened\'`', () => {
      beforeEach(() => {
        vm = new IssueToken({
          propsData: {
            reference,
            state: 'opened',
          },
        }).$mount();
      });

      it('shows green circle icon', () => {
        expect(vm.$el.querySelector('.issue-token-state-icon-open.fa.fa-circle-o')).toBeDefined();
      });
    });

    describe('`state: \'closed\'`', () => {
      beforeEach(() => {
        vm = new IssueToken({
          propsData: {
            reference,
            state: 'closed',
          },
        }).$mount();
      });

      it('shows red minus icon', () => {
        expect(vm.$el.querySelector('.issue-token-state-icon-closed.fa.fa-minus')).toBeDefined();
      });
    });
  });

  describe('with reference, title, state', () => {
    const state = 'opened';
    beforeEach(() => {
      vm = new IssueToken({
        propsData: {
          reference,
          title,
          state,
        },
      }).$mount();
    });

    it('shows reference, title, and state', () => {
      expect(vm.$refs.stateIcon.getAttribute('aria-label')).toEqual(state);
      expect(vm.$refs.reference.textContent.trim()).toEqual(reference);
      expect(vm.$refs.title.textContent.trim()).toEqual(title);
    });
  });

  describe('with fetchStatus', () => {
    describe('`canRemove: RelatedIssuesService.FETCHING_STATUS`', () => {
      beforeEach(() => {
        vm = new IssueToken({
          propsData: {
            reference,
            fetchStatus: RelatedIssuesService.FETCHING_STATUS,
          },
        }).$mount();
      });

      it('shows loading indicator/spinner', () => {
        expect(vm.$refs.fetchStatusIcon).toBeDefined();
      });
    });

    describe('`canRemove: RelatedIssuesService.FETCH_ERROR_STATUS`', () => {
      beforeEach(() => {
        vm = new IssueToken({
          propsData: {
            reference,
            fetchStatus: RelatedIssuesService.FETCH_ERROR_STATUS,
          },
        }).$mount();
      });

      it('tints the token red', () => {
        expect(vm.$el.classList.contains('issue-token-error')).toEqual(true);
      });
    });
  });

  describe('with canRemove', () => {
    describe('`canRemove: false` (default)', () => {
      beforeEach(() => {
        vm = new IssueToken({
          propsData: {
            reference,
          },
        }).$mount();
      });

      it('does not have remove button', () => {
        expect(vm.$el.querySelector('.issue-token-remove-button')).toBeNull();
      });
    });

    describe('`canRemove: true`', () => {
      beforeEach(() => {
        vm = new IssueToken({
          propsData: {
            reference,
            canRemove: true,
          },
        }).$mount();
      });

      it('has remove button', () => {
        expect(vm.$el.querySelector('.issue-token-remove-button')).toBeDefined();
      });
    });
  });

  describe('methods', () => {
    let removeRequestSpy;

    beforeEach(() => {
      vm = new IssueToken({
        propsData: {
          reference,
        },
      }).$mount();
      removeRequestSpy = jasmine.createSpy('spy');
      eventHub.$on('removeRequest', removeRequestSpy);
    });

    afterEach(() => {
      eventHub.$off('removeRequest', removeRequestSpy);
    });

    it('when getting checked', () => {
      expect(removeRequestSpy).not.toHaveBeenCalled();
      vm.onRemoveRequest();
      expect(removeRequestSpy).toHaveBeenCalled();
    });
  });
});
