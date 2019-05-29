// eslint-disable-next-line import/prefer-default-export
export const resetStore = store => {
  store.replaceState({
    showEmptyState: true,
    emptyState: 'loading',
    groups: [],
  });
};
