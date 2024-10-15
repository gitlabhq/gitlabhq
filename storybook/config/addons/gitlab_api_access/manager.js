// eslint-disable-next-line no-restricted-imports
import React from 'react';
import { addons, types } from '@storybook/addons';
import { useAddonState } from '@storybook/api';
import { AddonPanel, Form } from '@storybook/components';
import { ADDON_ID, STATE_ID, PANEL_ID, GITLAB_API_ACCESS_UPDATE_EVENT } from './constants';

/**
 * GitLab API Access is a Storybook extension that allows testing
 * UI components that depend on GitLab's REST or GraphQL APIs.
 *
 * Read https://docs.gitlab.com/ee/development/fe_guide/storybook
 * for more information.
 */
const h = React.createElement.bind(React);

// give a unique name for the panel
const GitLabAPIParametersPanel = () => {
  const channel = addons.getChannel();
  const [state, setState] = useAddonState(STATE_ID, {
    gitlabURL: process.env.GITLAB_URL,
    accessToken: process.env.API_ACCESS_TOKEN,
  });
  const updateState = (params) => {
    const newState = {
      ...state,
      ...params,
    };

    setState(newState);

    channel.emit(GITLAB_API_ACCESS_UPDATE_EVENT, newState);
  };

  const updateGitLabURL = (e) => {
    updateState({ gitlabURL: e.target.value });
  };

  const updateAccessToken = (e) => {
    updateState({ accessToken: e.target.value });
  };

  channel.emit(GITLAB_API_ACCESS_UPDATE_EVENT, state);

  return h(
    'div',
    {},
    h(
      Form.Field,
      { label: 'GitLab URL' },
      h(Form.Input, {
        type: 'text',
        value: state.gitlabURL,
        placeholder: 'https://gitlab.com',
        onChange: (e) => updateGitLabURL(e),
      }),
    ),
    h(
      Form.Field,
      { label: 'GitLab access token' },
      h(Form.Input, {
        type: 'password',
        value: state.accessToken,
        onChange: (e) => updateAccessToken(e),
      }),
    ),
  );
};

addons.register(ADDON_ID, () => {
  addons.add(PANEL_ID, {
    type: types.PANEL,
    title: 'GitLab API Access',
    render: ({ active, key }) => h(AddonPanel, { active, key }, h(GitLabAPIParametersPanel)),
  });
});
