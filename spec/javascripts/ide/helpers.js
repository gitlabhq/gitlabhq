import { decorateData } from 'ee/ide/stores/utils';
import state from 'ee/ide/stores/state';
import commitState from 'ee/ide/stores/modules/commit/state';

export const resetStore = (store) => {
  const newState = {
    ...state(),
    commit: commitState(),
  };
  store.replaceState(newState);
};

export const file = (name = 'name', id = name, type = '') => decorateData({
  id,
  type,
  icon: 'icon',
  url: 'url',
  name,
  path: name,
  lastCommit: {},
});
