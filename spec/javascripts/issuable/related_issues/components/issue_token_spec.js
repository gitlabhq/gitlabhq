import Vue from 'vue';
import eventHub from 'ee/related_issues/event_hub';
import issueToken from 'ee/related_issues/components/issue_token.vue';

describe('IssueToken', () => {
  const idKey = 200;
  const displayReference = 'foo/bar#123';
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
          idKey,
          displayReference,
        },
      }).$mount();
    });

    it('shows reference', () => {
      expect(vm.$el.textContent.trim()).toEqual(displayReference);
    });

    it('does not link without path specified', () => {
      expect(vm.$refs.link.tagName.toLowerCase()).toEqual('span');
      expect(vm.$refs.link.getAttribute('href')).toBeNull();
    });
  });

  describe('with reference and title supplied', () => {
    beforeEach(() => {
      vm = new IssueToken({
        propsData: {
          idKey,
          displayReference,
          title,
        },
      }).$mount();
    });

    it('shows reference and title', () => {
      expect(vm.$refs.reference.textContent.trim()).toEqual(displayReference);
      expect(vm.$refs.title.textContent.trim()).toEqual(title);
    });
  });

  describe('with path supplied', () => {
    const path = '/foo/bar/issues/123';
    beforeEach(() => {
      vm = new IssueToken({
        propsData: {
          idKey,
          displayReference,
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
            idKey,
            displayReference,
            state: 'opened',
          },
        }).$mount();
      });

      it('shows green circle icon', () => {
        expect(vm.$el.querySelector('.issue-token-state-icon-open.fa.fa-circle-o')).toBeDefined();
      });
    });

    describe('`state: \'reopened\'`', () => {
      beforeEach(() => {
        vm = new IssueToken({
          propsData: {
            idKey,
            displayReference,
            state: 'reopened',
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
            idKey,
            displayReference,
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
          idKey,
          displayReference,
          title,
          state,
        },
      }).$mount();
    });

    it('shows reference, title, and state', () => {
      const stateIcon = vm.$refs.reference.querySelector('svg');
      expect(stateIcon.getAttribute('aria-label')).toEqual(state);
      expect(vm.$refs.reference.textContent.trim()).toEqual(displayReference);
      expect(vm.$refs.title.textContent.trim()).toEqual(title);
    });
  });

  describe('with canRemove', () => {
    describe('`canRemove: false` (default)', () => {
      beforeEach(() => {
        vm = new IssueToken({
          propsData: {
            idKey,
            displayReference,
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
            idKey,
            displayReference,
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
          idKey,
          displayReference,
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
