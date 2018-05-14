/* global ListIssue */

import '~/vue_shared/models/label';
import '~/boards/models/issue';
import '~/boards/models/list';
import '~/boards/models/assignee';
import Store from '~/boards/stores/modal_store';

describe('Modal store', () => {
  let issue;
  let issue2;

  beforeEach(() => {
    // Setup default state
    Store.store.issues = [];
    Store.store.selectedIssues = [];

    issue = new ListIssue({
      title: 'Testing',
      id: 1,
      iid: 1,
      confidential: false,
      labels: [],
      assignees: [],
    });
    issue2 = new ListIssue({
      title: 'Testing',
      id: 1,
      iid: 2,
      confidential: false,
      labels: [],
      assignees: [],
    });
    Store.store.issues.push(issue);
    Store.store.issues.push(issue2);
  });

  it('returns selected count', () => {
    expect(Store.selectedCount()).toBe(0);
  });

  it('toggles the issue as selected', () => {
    Store.toggleIssue(issue);

    expect(issue.selected).toBe(true);
    expect(Store.selectedCount()).toBe(1);
  });

  it('toggles the issue as un-selected', () => {
    Store.toggleIssue(issue);
    Store.toggleIssue(issue);

    expect(issue.selected).toBe(false);
    expect(Store.selectedCount()).toBe(0);
  });

  it('toggles all issues as selected', () => {
    Store.toggleAll();

    expect(issue.selected).toBe(true);
    expect(issue2.selected).toBe(true);
    expect(Store.selectedCount()).toBe(2);
  });

  it('toggles all issues as un-selected', () => {
    Store.toggleAll();
    Store.toggleAll();

    expect(issue.selected).toBe(false);
    expect(issue2.selected).toBe(false);
    expect(Store.selectedCount()).toBe(0);
  });

  it('toggles all if a single issue is selected', () => {
    Store.toggleIssue(issue);
    Store.toggleAll();

    expect(issue.selected).toBe(true);
    expect(issue2.selected).toBe(true);
    expect(Store.selectedCount()).toBe(2);
  });

  it('adds issue to selected array', () => {
    issue.selected = true;
    Store.addSelectedIssue(issue);

    expect(Store.selectedCount()).toBe(1);
  });

  it('removes issue from selected array', () => {
    Store.addSelectedIssue(issue);
    Store.removeSelectedIssue(issue);

    expect(Store.selectedCount()).toBe(0);
  });

  it('returns selected issue index if present', () => {
    Store.toggleIssue(issue);

    expect(Store.selectedIssueIndex(issue)).toBe(0);
  });

  it('returns -1 if issue is not selected', () => {
    expect(Store.selectedIssueIndex(issue)).toBe(-1);
  });

  it('finds the selected issue', () => {
    Store.toggleIssue(issue);

    expect(Store.findSelectedIssue(issue)).toBe(issue);
  });

  it('does not find a selected issue', () => {
    expect(Store.findSelectedIssue(issue)).toBe(undefined);
  });

  it('does not remove from selected issue if tab is not all', () => {
    Store.store.activeTab = 'selected';

    Store.toggleIssue(issue);
    Store.toggleIssue(issue);

    expect(Store.store.selectedIssues.length).toBe(1);
    expect(Store.selectedCount()).toBe(0);
  });

  it('gets selected issue array with only selected issues', () => {
    Store.toggleIssue(issue);
    Store.toggleIssue(issue2);
    Store.toggleIssue(issue2);

    expect(Store.getSelectedIssues().length).toBe(1);
  });
});
