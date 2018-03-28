import {
  parseSastIssues,
  parseSastContainer,
  parseDastIssues,
  filterByKey,
  getUnapprovedVulnerabilities,
  textBuilder,
  statusIcon,
} from 'ee/vue_shared/security_reports/store/utils';
import { sastIssues, dockerReport, dast, parsedDast } from '../mock_data';

describe('security reports utils', () => {
  describe('parseSastIssues', () => {
    it('should parse the received issues', () => {
      const security = parseSastIssues(sastIssues, 'path')[0];
      expect(security.name).toEqual(sastIssues[0].message);
      expect(security.path).toEqual(sastIssues[0].file);
    });
  });

  describe('parseSastContainer', () => {
    it('parses sast container issues', () => {
      const parsed = parseSastContainer(dockerReport.vulnerabilities)[0];

      expect(parsed.name).toEqual(dockerReport.vulnerabilities[0].vulnerability);
      expect(parsed.priority).toEqual(dockerReport.vulnerabilities[0].severity);
      expect(parsed.path).toEqual(dockerReport.vulnerabilities[0].namespace);
      expect(parsed.nameLink).toEqual(
        `https://cve.mitre.org/cgi-bin/cvename.cgi?name=${
          dockerReport.vulnerabilities[0].vulnerability
        }`,
      );
    });
  });

  describe('parseDastIssues', () => {
    it('parsed dast report', () => {
      expect(parseDastIssues(dast.site.alerts)).toEqual(parsedDast);
    });
  });

  describe('filterByKey', () => {
    it('filters the array with the provided key', () => {
      const array1 = [{ id: '1234' }, { id: 'abg543' }, { id: '214swfA' }];
      const array2 = [{ id: '1234' }, { id: 'abg543' }, { id: '453OJKs' }];

      expect(filterByKey(array1, array2, 'id')).toEqual([{ id: '214swfA' }]);
    });
  });

  describe('getUnapprovedVulnerabilities', () => {
    it('return unapproved vulnerabilities', () => {
      const unapproved = getUnapprovedVulnerabilities(
        dockerReport.vulnerabilities,
        dockerReport.unapproved,
      );

      expect(unapproved.length).toEqual(dockerReport.unapproved.length);
      expect(unapproved[0].vulnerability).toEqual(dockerReport.unapproved[0]);
      expect(unapproved[1].vulnerability).toEqual(dockerReport.unapproved[1]);
    });
  });

  describe('textBuilder', () => {
    describe('with no issues', () => {
      it('should return no vulnerabiltities text', () => {
        expect(textBuilder()).toEqual(' detected no security vulnerabilities');
      });
    });

    describe('with only `all` issues', () => {
      it('should return no new vulnerabiltities text', () => {
        expect(textBuilder('', {}, 0, 0, 1)).toEqual(' detected no new security vulnerabilities');
      });
    });

    describe('with new issues and without base', () => {
      it('should return unable to compare text', () => {
        expect(textBuilder('', { head: 'foo' }, 1, 0, 0)).toEqual(
          ' was unable to compare existing and new vulnerabilities. It detected 1 vulnerability',
        );
      });
    });

    describe('with base and head', () => {
      describe('with only new issues', () => {
        it('should return new issues text', () => {
          expect(textBuilder('', { head: 'foo', base: 'foo' }, 1, 0, 0)).toEqual(
            ' detected 1 new vulnerability',
          );
        });
      });

      describe('with new and resolved issues', () => {
        it('should return new and fixed issues text', () => {
          expect(
            textBuilder('', { head: 'foo', base: 'foo' }, 1, 1, 0).replace(/\n+\s+/m, ' '),
          ).toEqual(' detected 1 new vulnerability and 1 fixed vulnerability');
        });
      });

      describe('with only resolved issues', () => {
        it('should return fixed issues text', () => {
          expect(textBuilder('', { head: 'foo', base: 'foo' }, 0, 1, 0)).toEqual(
            ' detected 1 fixed vulnerability',
          );
        });
      });
    });
  });

  describe('statusIcon', () => {
    describe('with failed report', () => {
      it('returns warning', () => {
        expect(statusIcon(true)).toEqual('warning');
      });
    });

    describe('with new issues', () => {
      it('returns warning', () => {
        expect(statusIcon(false, 1)).toEqual('warning');
      });
    });

    describe('with neutral issues', () => {
      it('returns warning', () => {
        expect(statusIcon(false, 0, 1)).toEqual('warning');
      });
    });

    describe('without new or neutal issues', () => {
      it('returns success', () => {
        expect(statusIcon()).toEqual('success');
      });
    });
  });
});
