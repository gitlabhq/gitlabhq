/* eslint-disable import/prefer-default-export */

export function createNote() {
  return {
    id: _.random(10000),
    canResolve: true,
    resolved: false,
    resolved_by: null,
    authorName: '',
    authorAvatar: '',
    noteTruncated: 'Lorem notesum...',
  };
}

