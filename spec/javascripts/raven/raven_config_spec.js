import Raven from 'raven-js';
import RavenConfig, { __RewireAPI__ as RavenConfigRewire } from '~/raven/raven_config';

describe('RavenConfig', () => {
  describe('init', () => {
    let options;

    beforeEach(() => {
      options = {
        sentryDsn: '//sentryDsn',
        ravenAssetUrl: '//ravenAssetUrl',
        currentUserId: 1,
        whitelistUrls: ['//gitlabUrl'],
        isProduction: true,
      };

      spyOn(RavenConfig, 'configure');
      spyOn(RavenConfig, 'bindRavenErrors');
      spyOn(RavenConfig, 'setUser');

      RavenConfig.init(options);
    });

    it('should set the options property', () => {
      expect(RavenConfig.options).toEqual(options);
    });

    it('should call the configure method', () => {
      expect(RavenConfig.configure).toHaveBeenCalled();
    });

    it('should call the error bindings method', () => {
      expect(RavenConfig.bindRavenErrors).toHaveBeenCalled();
    });

    it('should call setUser', () => {
      expect(RavenConfig.setUser).toHaveBeenCalled();
    });

    it('should not call setUser if there is no current user ID', () => {
      RavenConfig.setUser.calls.reset();

      RavenConfig.init({
        sentryDsn: '//sentryDsn',
        ravenAssetUrl: '//ravenAssetUrl',
        currentUserId: undefined,
        whitelistUrls: ['//gitlabUrl'],
        isProduction: true,
      });

      expect(RavenConfig.setUser).not.toHaveBeenCalled();
    });
  });

  describe('configure', () => {
    let options;
    let raven;

    beforeEach(() => {
      options = {
        sentryDsn: '//sentryDsn',
        whitelistUrls: ['//gitlabUrl'],
        isProduction: true,
      };

      raven = jasmine.createSpyObj('raven', ['install']);

      spyOn(Raven, 'config').and.returnValue(raven);

      RavenConfig.configure.call({
        options,
      });
    });

    it('should call Raven.config', () => {
      expect(Raven.config).toHaveBeenCalledWith(options.sentryDsn, {
        whitelistUrls: options.whitelistUrls,
        environment: 'production',
      });
    });

    it('should call Raven.install', () => {
      expect(raven.install).toHaveBeenCalled();
    });

    it('should set .environment to development if isProduction is false', () => {
      options.isProduction = false;

      RavenConfig.configure.call({
        options,
      });

      expect(Raven.config).toHaveBeenCalledWith(options.sentryDsn, {
        whitelistUrls: options.whitelistUrls,
        environment: 'development',
      });
    });
  });

  describe('setUser', () => {
    let ravenConfig;

    beforeEach(() => {
      ravenConfig = { options: { currentUserId: 1 } };
      spyOn(Raven, 'setUserContext');

      RavenConfig.setUser.call(ravenConfig);
    });

    it('should call .setUserContext', function () {
      expect(Raven.setUserContext).toHaveBeenCalledWith({
        id: ravenConfig.options.currentUserId,
      });
    });
  });

  describe('bindRavenErrors', () => {
    let $document;
    let $;

    beforeEach(() => {
      $document = jasmine.createSpyObj('$document', ['on']);
      $ = jasmine.createSpy('$').and.returnValue($document);

      RavenConfigRewire.__set__('$', $);

      RavenConfig.bindRavenErrors();
    });

    it('should query for document using jquery', () => {
      expect($).toHaveBeenCalledWith(document);
    });

    it('should call .on', function () {
      expect($document.on).toHaveBeenCalledWith('ajaxError.raven', RavenConfig.handleRavenErrors);
    });
  });

  describe('handleRavenErrors', () => {
    let event;
    let req;
    let config;
    let err;

    beforeEach(() => {
      event = {};
      req = { status: 'status', responseText: 'responseText', statusText: 'statusText' };
      config = { type: 'type', url: 'url', data: 'data' };
      err = {};

      spyOn(Raven, 'captureMessage');

      RavenConfig.handleRavenErrors(event, req, config, err);
    });

    it('should call Raven.captureMessage', () => {
      expect(Raven.captureMessage).toHaveBeenCalledWith(err, {
        extra: {
          type: config.type,
          url: config.url,
          data: config.data,
          status: req.status,
          response: req.responseText.substring(0, 100),
          error: err,
          event,
        },
      });
    });

    describe('if no err is provided', () => {
      beforeEach(() => {
        Raven.captureMessage.calls.reset();

        RavenConfig.handleRavenErrors(event, req, config);
      });

      it('should use req.statusText as the error value', () => {
        expect(Raven.captureMessage).toHaveBeenCalledWith(req.statusText, {
          extra: {
            type: config.type,
            url: config.url,
            data: config.data,
            status: req.status,
            response: req.responseText.substring(0, 100),
            error: req.statusText,
            event,
          },
        });
      });
    });
  });
});
