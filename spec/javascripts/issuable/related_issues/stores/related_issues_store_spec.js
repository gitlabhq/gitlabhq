import RelatedIssuesStore from '~/issuable/related_issues/stores/related_issues_store';

const issuable1 = {
  id: 200,
  reference: 'foo/bar#123',
  title: 'issue1',
  path: '/foo/bar/issues/123',
  state: 'opened',
  relation_path: '/foo/bar/issues/123/related_issues/1',
};

const issuable2 = {
  id: 201,
  reference: 'foo/bar#124',
  title: 'issue1',
  path: '/foo/bar/issues/124',
  state: 'opened',
  relation_path: '/foo/bar/issues/124/related_issues/1',
};

describe('RelatedIssuesStore', () => {
  let store;

  beforeEach(() => {
    store = new RelatedIssuesStore();
  });

  describe('setRelatedIssues', () => {
    it('defaults to empty array', () => {
      expect(store.state.relatedIssues).toEqual([]);
    });

    it('add issue', () => {
      const relatedIssues = [issuable1];
      store.setRelatedIssues(relatedIssues);

      expect(store.state.relatedIssues).toEqual(relatedIssues);
    });
  });

  describe('removeRelatedIssue', () => {
    it('remove issue', () => {
      const relatedIssues = [issuable1];
      store.state.relatedIssues = relatedIssues;

      store.removeRelatedIssue(issuable1.id);

      expect(store.state.relatedIssues).toEqual([]);
    });

    it('remove issue with multiple in store', () => {
      const relatedIssues = [issuable1, issuable2];
      store.state.relatedIssues = relatedIssues;

      store.removeRelatedIssue(issuable1.id);

      expect(store.state.relatedIssues).toEqual([issuable2]);
    });
  });

  describe('setPendingReferences', () => {
    it('defaults to empty array', () => {
      expect(store.state.pendingReferences).toEqual([]);
    });

    it('add reference', () => {
      const relatedIssues = [issuable1.reference];
      store.setPendingReferences(relatedIssues);

      expect(store.state.pendingReferences).toEqual(relatedIssues);
    });
  });

  describe('removePendingRelatedIssue', () => {
    it('remove issue', () => {
      const relatedIssues = [issuable1.reference];
      store.state.pendingReferences = relatedIssues;

      store.removePendingRelatedIssue(0);

      expect(store.state.pendingReferences).toEqual([]);
    });

    it('remove issue with multiple in store', () => {
      const relatedIssues = [issuable1.reference, issuable2.reference];
      store.state.pendingReferences = relatedIssues;

      store.removePendingRelatedIssue(0);

      expect(store.state.pendingReferences).toEqual([issuable2.reference]);
    });
  });
});
