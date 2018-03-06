import mixin from 'ee/vue_shared/security_reports/mixins/security_report_mixin';
import {
  parsedSastBaseStore,
  parsedSastIssuesHead,
  dockerReportParsed,
  parsedDast,
} from '../mock_data';

describe('security report mixin', () => {
  describe('sastText', () => {
    it('returns text for new and fixed issues', () => {
      expect(mixin.methods.sastText(
        parsedSastIssuesHead,
        parsedSastBaseStore,
      )).toEqual(
        'SAST improved on 1 security vulnerability and degraded on 2 security vulnerabilities',
      );
    });

    it('returns text for added issues', () => {
      expect(mixin.methods.sastText(parsedSastIssuesHead, [])).toEqual(
        'SAST degraded on 2 security vulnerabilities',
      );
    });

    it('returns text for fixed issues', () => {
      expect(mixin.methods.sastText([], parsedSastIssuesHead)).toEqual(
        'SAST improved on 2 security vulnerabilities',
      );
    });

    it('returns text for full report and no added or fixed issues', () => {
      expect(mixin.methods.sastText([], [], parsedSastIssuesHead)).toEqual(
        'SAST detected no new security vulnerabilities',
      );
    });
  });

  describe('translateText', () => {
    it('returns loading and error text for the given value', () => {
      expect(mixin.methods.translateText('sast')).toEqual({
        error: 'Failed to load sast report',
        loading: 'Loading sast report',
      });
    });
  });

  describe('checkReportStatus', () => {
    it('returns loading when loading is true', () => {
      expect(mixin.methods.checkReportStatus(true, false)).toEqual('loading');
    });

    it('returns error when error is true', () => {
      expect(mixin.methods.checkReportStatus(false, true)).toEqual('error');
    });

    it('returns success when loading and error are false', () => {
      expect(mixin.methods.checkReportStatus(false, false)).toEqual('success');
    });
  });

  describe('sastContainerText', () => {
    it('returns no vulnerabitilties text', () => {
      expect(mixin.methods.sastContainerText()).toEqual(
        'SAST:container no vulnerabilities were found',
      );
    });

    it('returns approved vulnerabilities text', () => {
      expect(
        mixin.methods.sastContainerText(
          dockerReportParsed.vulnerabilities,
          dockerReportParsed.approved,
        ),
      ).toEqual(
        'SAST:container found 1 approved vulnerability',
      );
    });

    it('returns unnapproved vulnerabilities text', () => {
      expect(
        mixin.methods.sastContainerText(
          dockerReportParsed.vulnerabilities,
          [],
          dockerReportParsed.unapproved,
        ),
      ).toEqual(
        'SAST:container found 2 vulnerabilities',
      );
    });

    it('returns approved & unapproved text', () => {
      expect(mixin.methods.sastContainerText(
        dockerReportParsed.vulnerabilities,
        dockerReportParsed.approved,
        dockerReportParsed.unapproved,
      )).toEqual(
        'SAST:container found 3 vulnerabilities, of which 1 is approved',
      );
    });
  });

  describe('dastText', () => {
    it('returns dast text', () => {
      expect(mixin.methods.dastText(parsedDast)).toEqual(
        'DAST detected 2 alerts by analyzing the review app',
      );
    });

    it('returns no alert text', () => {
      expect(mixin.methods.dastText()).toEqual('DAST detected no alerts by analyzing the review app');
    });
  });
});
