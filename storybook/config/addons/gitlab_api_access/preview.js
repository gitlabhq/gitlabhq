import { addons } from '@storybook/addons';
import { GlBadge } from '@gitlab/ui';
import { FORCE_REMOUNT } from '@storybook/core-events';
import VueApollo from 'vue-apollo';
import axios from '~/lib/utils/axios_utils';
import createDefaultClient from '~/lib/graphql';
import { GITLAB_API_ACCESS_UPDATE_EVENT } from './constants';

/**
 * GitLab API Access is a Storybook extension that allows testing
 * UI components that depend on GitLab's REST or GraphQL APIs.
 *
 * Read https://docs.gitlab.com/ee/development/fe_guide/storybook
 * for more information.
 */
const channel = addons.getChannel();
let gitlabApiAccessParams;
let refreshApolloClient = false;
let apolloClient = null;

const setGitLabAPIAccessParams = ({ gitlabURL, accessToken }) => {
  window.gon.relative_url_root = gitlabURL;

  axios.defaults.headers.common['PRIVATE-TOKEN'] = accessToken;
  gitlabApiAccessParams = { gitlabURL, accessToken };
  refreshApolloClient = true;
};

const createVueApollo = (resolvers = {}, config = {}) => {
  // Avoids creating a new Apollo client every time that the story rerenders
  if (!apolloClient || refreshApolloClient) {
    refreshApolloClient = false;
    apolloClient = new VueApollo({
      defaultClient: createDefaultClient(
        {
          ...resolvers,
        },
        {
          ...config,
          httpHeaders: {
            Authorization: `Bearer ${gitlabApiAccessParams.accessToken}`,
          },
        },
      ),
    });
  }

  return apolloClient;
};

channel.addListener(GITLAB_API_ACCESS_UPDATE_EVENT, (params) => {
  setGitLabAPIAccessParams(params);

  const storyId = new URLSearchParams(window.location.search).get('id');

  // If we don’t force remount, Vue Apollo is not updated with the new parameters
  addons.channel.emit(FORCE_REMOUNT, { storyId });
});

/*
 * Story decorator used to inject a VueApollo client factory
 * that contains the GitLab API access parameters.
 */
export const withGitLabAPIAccess = (story, context) => {
  Object.assign(context, { createVueApollo });

  return {
    components: {
      story,
      GlBadge,
    },
    template: `
    <div>
      <div class="gl-flex gl-justify-end">
        <gl-badge variant="info">Requires API access</gl-badge>
      </div>
      <story />
    </div>
    `,
  };
};

/*
 * Initializes the GitLab API access parameters
 * with values coming from the environment.
 */
export const initializeGitLabAPIAccess = () => {
  setGitLabAPIAccessParams({
    gitlabURL: process.env.GITLAB_URL,
    accessToken: process.env.API_ACCESS_TOKEN,
  });
};
