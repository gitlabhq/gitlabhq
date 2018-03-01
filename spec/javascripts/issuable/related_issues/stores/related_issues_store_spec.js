import RelatedIssuesStore from 'ee/related_issues/stores/related_issues_store';

import { issuable1, issuable2, issuable3, issuable4, issuable5 } from '../mock_data';

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

  describe('updateIssueOrder', () => {
    it('updates issue order', () => {
      const relatedIssues = [issuable1, issuable2, issuable3, issuable4, issuable5];
      store.state.relatedIssues = relatedIssues;

      expect(store.state.relatedIssues[3].id).toBe(issuable4.id);
      store.updateIssueOrder(3, 0);
      expect(store.state.relatedIssues[0].id).toBe(issuable4.id);
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
