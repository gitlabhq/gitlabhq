export const defaultProps = {
  endpoint: '/foo/bar/issues/1/related_issues',
  currentNamespacePath: 'foo',
  currentProjectPath: 'bar',
};

export const issuable1 = {
  id: 200,
  epic_issue_id: 1,
  reference: 'foo/bar#123',
  displayReference: '#123',
  title: 'some title',
  path: '/foo/bar/issues/123',
  state: 'opened',
};

export const issuable2 = {
  id: 201,
  epic_issue_id: 2,
  reference: 'foo/bar#124',
  displayReference: '#124',
  title: 'some other thing',
  path: '/foo/bar/issues/124',
  state: 'opened',
};

export const issuable3 = {
  id: 202,
  epic_issue_id: 3,
  reference: 'foo/bar#125',
  displayReference: '#125',
  title: 'some other other thing',
  path: '/foo/bar/issues/125',
  state: 'opened',
};

export const issuable4 = {
  id: 203,
  epic_issue_id: 4,
  reference: 'foo/bar#126',
  displayReference: '#126',
  title: 'some other other other thing',
  path: '/foo/bar/issues/126',
  state: 'opened',
};

export const issuable5 = {
  id: 204,
  epic_issue_id: 5,
  reference: 'foo/bar#127',
  displayReference: '#127',
  title: 'some other other other thing',
  path: '/foo/bar/issues/127',
  state: 'opened',
};
