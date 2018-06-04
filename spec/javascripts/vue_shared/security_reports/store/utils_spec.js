import sha1 from 'sha1';
import {
  findIssueIndex,
  parseSastIssues,
  parseDependencyScanningIssues,
  parseSastContainer,
  parseDastIssues,
  filterByKey,
  getUnapprovedVulnerabilities,
  textBuilder,
  statusIcon,
} from 'ee/vue_shared/security_reports/store/utils';
import {
  oldSastIssues,
  sastIssues,
  sastFeedbacks,
  dependencyScanningIssues,
  dependencyScanningFeedbacks,
  dockerReport,
  containerScanningFeedbacks,
  dast,
  dastFeedbacks,
  parsedDast,
} from '../mock_data';

describe('security reports utils', () => {
  describe('findIssueIndex', () => {
    let issuesList;

    beforeEach(() => {
      issuesList = [
        { project_fingerprint: 'abc123' },
        { project_fingerprint: 'abc456' },
        { project_fingerprint: 'abc789' },
      ];
    });

    it('returns index of found issue', () => {
      const issue = {
        project_fingerprint: 'abc456',
      };

      expect(findIssueIndex(issuesList, issue)).toEqual(1);
    });

    it('returns -1 when issue is not found', () => {
      const issue = {
        project_fingerprint: 'foo',
      };

      expect(findIssueIndex(issuesList, issue)).toEqual(-1);
    });
  });

  describe('parseSastIssues', () => {
    it('should parse the received issues with old JSON format', () => {
      const parsed = parseSastIssues(oldSastIssues, [], 'path')[0];
      expect(parsed.title).toEqual(sastIssues[0].message);
      expect(parsed.path).toEqual(sastIssues[0].location.file);
      expect(parsed.project_fingerprint).toEqual(sha1(sastIssues[0].cve));
    });

    it('should parse the received issues with new JSON format', () => {
      const parsed = parseSastIssues(sastIssues, [], 'path')[0];
      expect(parsed.title).toEqual(sastIssues[0].message);
      expect(parsed.path).toEqual(sastIssues[0].location.file);
      expect(parsed.project_fingerprint).toEqual(sha1(sastIssues[0].cve));
    });

    it('includes vulnerability feedbacks', () => {
      const parsed = parseSastIssues(
        sastIssues,
        sastFeedbacks,
        'path',
      )[0];
      expect(parsed.hasIssue).toEqual(true);
      expect(parsed.isDismissed).toEqual(true);
      expect(parsed.dismissalFeedback).toEqual(sastFeedbacks[0]);
      expect(parsed.issueFeedback).toEqual(sastFeedbacks[1]);
    });
  });

  describe('parseDependencyScanningIssues', () => {
    it('should parse the received issues', () => {
      const parsed = parseDependencyScanningIssues(dependencyScanningIssues, [], 'path')[0];
      expect(parsed.title).toEqual(dependencyScanningIssues[0].message);
      expect(parsed.path).toEqual(dependencyScanningIssues[0].file);
      expect(parsed.project_fingerprint).toEqual(sha1(dependencyScanningIssues[0].cve));
    });

    it('uses message to generate sha1 when cve is undefined', () => {
      const issuesWithoutCve = dependencyScanningIssues.map(issue => ({
        ...issue,
        cve: undefined,
      }));
      const parsed = parseDependencyScanningIssues(issuesWithoutCve, [], 'path')[0];
      expect(parsed.project_fingerprint).toEqual(sha1(dependencyScanningIssues[0].message));
    });

    it('includes vulnerability feedbacks', () => {
      const parsed = parseDependencyScanningIssues(
        dependencyScanningIssues,
        dependencyScanningFeedbacks,
        'path',
      )[0];
      expect(parsed.hasIssue).toEqual(true);
      expect(parsed.isDismissed).toEqual(true);
      expect(parsed.dismissalFeedback).toEqual(dependencyScanningFeedbacks[0]);
      expect(parsed.issueFeedback).toEqual(dependencyScanningFeedbacks[1]);
    });
  });

  describe('parseSastContainer', () => {
    it('parses sast container issues', () => {
      const parsed = parseSastContainer(dockerReport.vulnerabilities)[0];
      const issue = dockerReport.vulnerabilities[0];

      expect(parsed.title).toEqual(issue.vulnerability);
      expect(parsed.path).toEqual(issue.namespace);
      expect(parsed.identifiers).toEqual([{
        type: 'CVE',
        name: issue.vulnerability,
        value: issue.vulnerability,
        url: `https://cve.mitre.org/cgi-bin/cvename.cgi?name=${issue.vulnerability}`,
      }]);
      expect(parsed.project_fingerprint).toEqual(
        sha1(`${issue.namespace}:${issue.vulnerability}:${issue.featurename}:${issue.featureversion}`));
    });

    it('includes vulnerability feedbacks', () => {
      const parsed = parseSastContainer(
        dockerReport.vulnerabilities,
        containerScanningFeedbacks,
      )[0];
      expect(parsed.hasIssue).toEqual(true);
      expect(parsed.isDismissed).toEqual(true);
      expect(parsed.dismissalFeedback).toEqual(containerScanningFeedbacks[0]);
      expect(parsed.issueFeedback).toEqual(containerScanningFeedbacks[1]);
    });
  });

  describe('parseDastIssues', () => {
    it('parses dast report', () => {
      expect(parseDastIssues(dast.site.alerts)).toEqual(parsedDast);
    });

    it('includes vulnerability feedbacks', () => {
      const parsed = parseDastIssues(
        dast.site.alerts,
        dastFeedbacks,
      )[0];
      expect(parsed.hasIssue).toEqual(true);
      expect(parsed.isDismissed).toEqual(true);
      expect(parsed.dismissalFeedback).toEqual(dastFeedbacks[0]);
      expect(parsed.issueFeedback).toEqual(dastFeedbacks[1]);
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
        expect(textBuilder('', { head: 'foo', base: 'bar' }, 0, 0, 0)).toEqual(
          ' detected no security vulnerabilities',
        );
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
          ' detected 1 vulnerability for the source branch only',
        );
      });

      it('should return unable to compare text with no vulnerability', () => {
        expect(textBuilder('', { head: 'foo' }, 0, 0, 0)).toEqual(
          ' detected no vulnerabilities for the source branch only',
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
        expect(statusIcon(false, true)).toEqual('warning');
      });
    });

    describe('with new issues', () => {
      it('returns warning', () => {
        expect(statusIcon(false, false, 1)).toEqual('warning');
      });
    });

    describe('with neutral issues', () => {
      it('returns warning', () => {
        expect(statusIcon(false, false, 0, 1)).toEqual('warning');
      });
    });

    describe('without new or neutal issues', () => {
      it('returns success', () => {
        expect(statusIcon()).toEqual('success');
      });
    });
  });
});
