/* global ClassSpecHelper */

/*= require raven */
/*= require lib/utils/load_script */
/*= require raven_config */
/*= require class_spec_helper */

describe('RavenConfig', () => {
  const global = window.gl || (window.gl = {});
  const RavenConfig = global.RavenConfig;

  it('should be defined in the global scope', () => {
    expect(RavenConfig).toBeDefined();
  });

  describe('.init', () => {
    beforeEach(() => {
      spyOn(global.LoadScript, 'load').and.callThrough();
      spyOn(document, 'querySelector').and.returnValue(undefined);
      spyOn(RavenConfig, 'configure');
      spyOn(RavenConfig, 'bindRavenErrors');
      spyOn(RavenConfig, 'setUser');
      spyOn(Promise, 'reject');
    });

    ClassSpecHelper.itShouldBeAStaticMethod(RavenConfig, 'init');

    describe('when called', () => {
      let options;
      let initPromise;

      beforeEach(() => {
        options = {
          sentryDsn: '//sentryDsn',
          ravenAssetUrl: '//ravenAssetUrl',
          currentUserId: 1,
          whitelistUrls: ['//gitlabUrl'],
          isProduction: true,
        };
        initPromise = RavenConfig.init(options);
      });

      it('should set the options property', () => {
        expect(RavenConfig.options).toEqual(options);
      });

      it('should load a #raven-js script with the raven asset URL', () => {
        expect(global.LoadScript.load).toHaveBeenCalledWith(options.ravenAssetUrl, 'raven-js');
      });

      it('should return a promise', () => {
        expect(initPromise).toEqual(jasmine.any(Promise));
      });

      it('should call the configure method', () => {
        initPromise.then(() => {
          expect(RavenConfig.configure).toHaveBeenCalled();
        });
      });

      it('should call the error bindings method', () => {
        initPromise.then(() => {
          expect(RavenConfig.bindRavenErrors).toHaveBeenCalled();
        });
      });

      it('should call setUser', () => {
        initPromise.then(() => {
          expect(RavenConfig.setUser).toHaveBeenCalled();
        });
      });
    });

    it('should not call setUser if there is no current user ID', () => {
      RavenConfig.init({
        sentryDsn: '//sentryDsn',
        ravenAssetUrl: '//ravenAssetUrl',
        currentUserId: undefined,
        whitelistUrls: ['//gitlabUrl'],
        isProduction: true,
      });

      expect(RavenConfig.setUser).not.toHaveBeenCalled();
    });

    it('should reject if there is no Sentry DSN', () => {
      RavenConfig.init({
        sentryDsn: undefined,
        ravenAssetUrl: '//ravenAssetUrl',
        currentUserId: 1,
        whitelistUrls: ['//gitlabUrl'],
        isProduction: true,
      });

      expect(Promise.reject).toHaveBeenCalledWith('sentry dsn and raven asset url is required');
    });

    it('should reject if there is no Raven asset URL', () => {
      RavenConfig.init({
        sentryDsn: '//sentryDsn',
        ravenAssetUrl: undefined,
        currentUserId: 1,
        whitelistUrls: ['//gitlabUrl'],
        isProduction: true,
      });

      expect(Promise.reject).toHaveBeenCalledWith('sentry dsn and raven asset url is required');
    });
  });

  describe('.configure', () => {
    ClassSpecHelper.itShouldBeAStaticMethod(RavenConfig, 'configure');

    describe('when called', () => {
      beforeEach(() => {});
    });
  });

  describe('.setUser', () => {
    ClassSpecHelper.itShouldBeAStaticMethod(RavenConfig, 'setUser');

    describe('when called', () => {
      beforeEach(() => {});
    });
  });

  describe('.bindRavenErrors', () => {
    ClassSpecHelper.itShouldBeAStaticMethod(RavenConfig, 'bindRavenErrors');

    describe('when called', () => {
      beforeEach(() => {});
    });
  });

  describe('.handleRavenErrors', () => {
    ClassSpecHelper.itShouldBeAStaticMethod(RavenConfig, 'handleRavenErrors');

    describe('when called', () => {
      beforeEach(() => {});
    });
  });
});
