import { decorateData } from '~/ide/stores/utils';
import state from '~/ide/stores/state';
import commitState from '~/ide/stores/modules/commit/state';
import mergeRequestsState from '~/ide/stores/modules/merge_requests/state';
import pipelinesState from '~/ide/stores/modules/pipelines/state';

export const resetStore = store => {
  const newState = {
    ...state(),
    commit: commitState(),
    mergeRequests: mergeRequestsState(),
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
