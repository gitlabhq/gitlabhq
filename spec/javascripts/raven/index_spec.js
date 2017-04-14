import RavenConfig from '~/raven/raven_config';
import index from '~/raven/index';

describe('RavenConfig options', () => {
  let sentryDsn;
  let currentUserId;
  let gitlabUrl;
  let isProduction;
  let indexReturnValue;

  beforeEach(() => {
    sentryDsn = 'sentryDsn';
    currentUserId = 'currentUserId';
    gitlabUrl = 'gitlabUrl';
    isProduction = 'isProduction';

    window.gon = {
      sentry_dsn: sentryDsn,
      current_user_id: currentUserId,
      gitlab_url: gitlabUrl,
      is_production: isProduction,
    };

    spyOn(RavenConfig, 'init');

    indexReturnValue = index();
  });

  it('should init with .sentryDsn, .currentUserId, .whitelistUrls and .isProduction', () => {
    expect(RavenConfig.init).toHaveBeenCalledWith({
      sentryDsn,
      currentUserId,
      whitelistUrls: [gitlabUrl],
      isProduction,
    });
  });

  it('should return RavenConfig', () => {
    expect(indexReturnValue).toBe(RavenConfig);
  });
});
