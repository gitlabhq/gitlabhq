import Raven from 'raven-js';
import RavenConfig from '~/raven/raven_config';
import ClassSpecHelper from '../helpers/class_spec_helper';

fdescribe('RavenConfig', () => {
  describe('init', () => {
    beforeEach(() => {
      spyOn(RavenConfig, 'configure');
      spyOn(RavenConfig, 'bindRavenErrors');
      spyOn(RavenConfig, 'setUser');
    });

    ClassSpecHelper.itShouldBeAStaticMethod(RavenConfig, 'init');

    describe('when called', () => {
      let options;

      beforeEach(() => {
        options = {
          sentryDsn: '//sentryDsn',
          ravenAssetUrl: '//ravenAssetUrl',
          currentUserId: 1,
          whitelistUrls: ['//gitlabUrl'],
          isProduction: true,
        };

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
  });

  describe('configure', () => {
    ClassSpecHelper.itShouldBeAStaticMethod(RavenConfig, 'configure');

    describe('when called', () => {
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
        spyOn(Raven, 'install');

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
        expect(Raven.install).toHaveBeenCalled();
      });

      describe('if isProduction is false', () => {
        beforeEach(() => {
          options.isProduction = false;

          RavenConfig.configure.call({
            options,
          });
        });

        it('should set .environment to development', () => {
          expect(Raven.config).toHaveBeenCalledWith(options.sentryDsn, {
            whitelistUrls: options.whitelistUrls,
            environment: 'development',
          });
        });
      });
    });
  });

  describe('setUser', () => {
    ClassSpecHelper.itShouldBeAStaticMethod(RavenConfig, 'setUser');

    describe('when called', () => {
      beforeEach(() => {});
    });
  });

  describe('bindRavenErrors', () => {
    ClassSpecHelper.itShouldBeAStaticMethod(RavenConfig, 'bindRavenErrors');

    describe('when called', () => {
      beforeEach(() => {});
    });
  });

  describe('handleRavenErrors', () => {
    ClassSpecHelper.itShouldBeAStaticMethod(RavenConfig, 'handleRavenErrors');

    describe('when called', () => {
      beforeEach(() => {});
    });
  });
});
