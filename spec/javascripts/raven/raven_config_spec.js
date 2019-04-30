import Raven from 'raven-js';
import RavenConfig from '~/raven/raven_config';

describe('RavenConfig', () => {
  describe('IGNORE_ERRORS', () => {
    it('should be an array of strings', () => {
      const areStrings = RavenConfig.IGNORE_ERRORS.every(error => typeof error === 'string');

      expect(areStrings).toBe(true);
    });
  });

  describe('IGNORE_URLS', () => {
    it('should be an array of regexps', () => {
      const areRegExps = RavenConfig.IGNORE_URLS.every(url => url instanceof RegExp);

      expect(areRegExps).toBe(true);
    });
  });

  describe('SAMPLE_RATE', () => {
    it('should be a finite number', () => {
      expect(typeof RavenConfig.SAMPLE_RATE).toEqual('number');
    });
  });

  describe('init', () => {
    const options = {
      currentUserId: 1,
    };

    beforeEach(() => {
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

      options.currentUserId = undefined;

      RavenConfig.init(options);

      expect(RavenConfig.setUser).not.toHaveBeenCalled();
    });
  });

  describe('configure', () => {
    let raven;
    let ravenConfig;
    const options = {
      sentryDsn: '//sentryDsn',
      whitelistUrls: ['//gitlabUrl', 'webpack-internal://'],
      environment: 'test',
      release: 'revision',
      tags: {
        revision: 'revision',
      },
    };

    beforeEach(() => {
      ravenConfig = jasmine.createSpyObj('ravenConfig', ['shouldSendSample']);
      raven = jasmine.createSpyObj('raven', ['install']);

      spyOn(Raven, 'config').and.returnValue(raven);

      ravenConfig.options = options;
      ravenConfig.IGNORE_ERRORS = 'ignore_errors';
      ravenConfig.IGNORE_URLS = 'ignore_urls';

      RavenConfig.configure.call(ravenConfig);
    });

    it('should call Raven.config', () => {
      expect(Raven.config).toHaveBeenCalledWith(options.sentryDsn, {
        release: options.release,
        tags: options.tags,
        whitelistUrls: options.whitelistUrls,
        environment: 'test',
        ignoreErrors: ravenConfig.IGNORE_ERRORS,
        ignoreUrls: ravenConfig.IGNORE_URLS,
        shouldSendCallback: jasmine.any(Function),
      });
    });

    it('should call Raven.install', () => {
      expect(raven.install).toHaveBeenCalled();
    });

    it('should set environment from options', () => {
      ravenConfig.options.environment = 'development';

      RavenConfig.configure.call(ravenConfig);

      expect(Raven.config).toHaveBeenCalledWith(options.sentryDsn, {
        release: options.release,
        tags: options.tags,
        whitelistUrls: options.whitelistUrls,
        environment: 'development',
        ignoreErrors: ravenConfig.IGNORE_ERRORS,
        ignoreUrls: ravenConfig.IGNORE_URLS,
        shouldSendCallback: jasmine.any(Function),
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

    it('should call .setUserContext', function() {
      expect(Raven.setUserContext).toHaveBeenCalledWith({
        id: ravenConfig.options.currentUserId,
      });
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
          response: req.responseText,
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
            response: req.responseText,
            error: req.statusText,
            event,
          },
        });
      });
    });

    describe('if no req.responseText is provided', () => {
      beforeEach(() => {
        req.responseText = undefined;

        Raven.captureMessage.calls.reset();

        RavenConfig.handleRavenErrors(event, req, config, err);
      });

      it('should use `Unknown response text` as the response', () => {
        expect(Raven.captureMessage).toHaveBeenCalledWith(err, {
          extra: {
            type: config.type,
            url: config.url,
            data: config.data,
            status: req.status,
            response: 'Unknown response text',
            error: err,
            event,
          },
        });
      });
    });
  });

  describe('shouldSendSample', () => {
    let randomNumber;

    beforeEach(() => {
      RavenConfig.SAMPLE_RATE = 50;

      spyOn(Math, 'random').and.callFake(() => randomNumber);
    });

    it('should call Math.random', () => {
      RavenConfig.shouldSendSample();

      expect(Math.random).toHaveBeenCalled();
    });

    it('should return true if the sample rate is greater than the random number * 100', () => {
      randomNumber = 0.1;

      expect(RavenConfig.shouldSendSample()).toBe(true);
    });

    it('should return false if the sample rate is less than the random number * 100', () => {
      randomNumber = 0.9;

      expect(RavenConfig.shouldSendSample()).toBe(false);
    });

    it('should return true if the sample rate is equal to the random number * 100', () => {
      randomNumber = 0.5;

      expect(RavenConfig.shouldSendSample()).toBe(true);
    });
  });
});
