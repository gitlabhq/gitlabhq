import RavenConfig from '~/raven/raven_config';
import index from '~/raven/index';

describe('RavenConfig options', () => {
  const sentryDsn = 'sentryDsn';
  const currentUserId = 'currentUserId';
  const gitlabUrl = 'gitlabUrl';
  const environment = 'test';
  const revision = 'revision';
  let indexReturnValue;

  beforeEach(() => {
    window.gon = {
      sentry_dsn: sentryDsn,
      sentry_environment: environment,
      current_user_id: currentUserId,
      gitlab_url: gitlabUrl,
      revision,
    };

    process.env.HEAD_COMMIT_SHA = revision;

    spyOn(RavenConfig, 'init');

    indexReturnValue = index();
  });

  it('should init with .sentryDsn, .currentUserId, .whitelistUrls and environment', () => {
    expect(RavenConfig.init).toHaveBeenCalledWith({
      sentryDsn,
      currentUserId,
      whitelistUrls: [gitlabUrl, 'webpack-internal://'],
      environment,
      release: revision,
      tags: {
        revision,
      },
    });
  });

  it('should return RavenConfig', () => {
    expect(indexReturnValue).toBe(RavenConfig);
  });
});
