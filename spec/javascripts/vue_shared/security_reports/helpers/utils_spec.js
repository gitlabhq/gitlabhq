import {
  parseSastIssues,
  parseCodeclimateMetrics,
  parseSastContainer,
  setSastReport,
  setDastReport,
} from 'ee/vue_shared/security_reports/helpers/utils';
import {
  baseIssues,
  sastIssues,
  sastIssuesBase,
  parsedSastIssuesStore,
  parsedSastBaseStore,
  allIssuesParsed,
  parsedSastIssuesHead,
  dockerReport,
  dockerReportParsed,
  dast,
  parsedDast,
} from '../mock_data';

describe('security reports utils', () => {
  describe('parseSastIssues', () => {
    it('should parse the received issues', () => {
      const security = parseSastIssues(sastIssues, 'path')[0];
      expect(security.name).toEqual(sastIssues[0].message);
      expect(security.path).toEqual(sastIssues[0].file);
    });
  });

  describe('parseCodeclimateMetrics', () => {
    it('should parse the received issues', () => {
      const codequality = parseCodeclimateMetrics(baseIssues, 'path')[0];
      expect(codequality.name).toEqual(baseIssues[0].check_name);
      expect(codequality.path).toEqual(baseIssues[0].location.path);
      expect(codequality.line).toEqual(baseIssues[0].location.lines.begin);
    });
  });

  describe('setSastReport', () => {
    it('should set security issues with head', () => {
      const securityReport = setSastReport({ head: sastIssues, headBlobPath: 'path' });
      expect(securityReport.newIssues).toEqual(parsedSastIssuesStore);
    });

    it('should set security issues with head and base', () => {
      const securityReport = setSastReport({
        head: sastIssues,
        headBlobPath: 'path',
        base: sastIssuesBase,
        baseBlobPath: 'path',
      });

      expect(securityReport.newIssues).toEqual(parsedSastIssuesHead);
      expect(securityReport.resolvedIssues).toEqual(parsedSastBaseStore);
      expect(securityReport.allIssues).toEqual(allIssuesParsed);
    });
  });

  describe('parseSastContainer', () => {
    it('parses sast container report', () => {
      expect(parseSastContainer(dockerReport.vulnerabilities)).toEqual(
        dockerReportParsed.vulnerabilities,
      );
    });
  });

  describe('dastReport', () => {
    it('parsed dast report', () => {
      expect(setDastReport(dast)).toEqual(parsedDast);
    });
  });
});
