import { decorateData } from '~/ide/stores/utils';
import state from '~/ide/stores/state';
import commitState from '~/ide/stores/modules/commit/state';
import pipelinesState from '~/ide/stores/modules/pipelines/state';

export const resetStore = store => {
  const newState = {
    ...state(),
    commit: commitState(),
    pipelines: pipelinesState(),
  };
  store.replaceState(newState);
};

export const file = (name = 'name', id = name, type = '') =>
  decorateData({
    id,
    type,
    icon: 'icon',
    url: 'url',
    name,
    path: name,
    lastCommit: {},
  });
