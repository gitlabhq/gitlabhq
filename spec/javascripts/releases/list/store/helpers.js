import state from '~/releases/list/store/state';

// eslint-disable-next-line import/prefer-default-export
export const resetStore = store => {
  store.replaceState(state());
};
