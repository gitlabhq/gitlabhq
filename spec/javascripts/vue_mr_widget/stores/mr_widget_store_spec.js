import MergeRequestStore from 'ee/vue_merge_request_widget/stores/mr_widget_store';
import { stateKey } from '~/vue_merge_request_widget/stores/state_maps';
import mockData, {
  headIssues,
  baseIssues,
  securityIssues,
  parsedBaseIssues,
  parsedHeadIssues,
  parsedSecurityIssuesStore,
  dockerReport,
  dockerReportParsed,
  dast,
  parsedDast,
} from '../mock_data';

describe('MergeRequestStore', () => {
  let store;

  beforeEach(() => {
    store = new MergeRequestStore(mockData);
  });

  describe('setData', () => {
    it('should set hasSHAChanged when the diff SHA changes', () => {
      store.setData({ ...mockData, diff_head_sha: 'a-different-string' });
      expect(store.hasSHAChanged).toBe(true);
    });

    it('should not set hasSHAChanged when other data changes', () => {
      store.setData({ ...mockData, work_in_progress: !mockData.work_in_progress });
      expect(store.hasSHAChanged).toBe(false);
    });

    describe('isPipelinePassing', () => {
      it('is true when the CI status is `success`', () => {
        store.setData({ ...mockData, ci_status: 'success' });
        expect(store.isPipelinePassing).toBe(true);
      });

      it('is true when the CI status is `success_with_warnings`', () => {
        store.setData({ ...mockData, ci_status: 'success_with_warnings' });
        expect(store.isPipelinePassing).toBe(true);
      });

      it('is false when the CI status is `failed`', () => {
        store.setData({ ...mockData, ci_status: 'failed' });
        expect(store.isPipelinePassing).toBe(false);
      });

      it('is false when the CI status is anything except `success`', () => {
        store.setData({ ...mockData, ci_status: 'foobarbaz' });
        expect(store.isPipelinePassing).toBe(false);
      });
    });

    describe('isPipelineSkipped', () => {
      it('should set isPipelineSkipped=true when the CI status is `skipped`', () => {
        store.setData({ ...mockData, ci_status: 'skipped' });
        expect(store.isPipelineSkipped).toBe(true);
      });

      it('should set isPipelineSkipped=false when the CI status is anything except `skipped`', () => {
        store.setData({ ...mockData, ci_status: 'foobarbaz' });
        expect(store.isPipelineSkipped).toBe(false);
      });
    });

    describe('isNothingToMergeState', () => {
      it('returns true when nothingToMerge', () => {
        store.state = stateKey.nothingToMerge;
        expect(store.isNothingToMergeState).toEqual(true);
      });

      it('returns false when not nothingToMerge', () => {
        store.state = 'state';
        expect(store.isNothingToMergeState).toEqual(false);
      });
    });
  });

  describe('compareCodeclimateMetrics', () => {
    beforeEach(() => {
      store.compareCodeclimateMetrics(headIssues, baseIssues, 'headPath', 'basePath');
    });

    it('should return the new issues', () => {
      expect(store.codeclimateMetrics.newIssues[0]).toEqual(parsedHeadIssues[0]);
    });

    it('should return the resolved issues', () => {
      expect(store.codeclimateMetrics.resolvedIssues[0]).toEqual(parsedBaseIssues[0]);
    });
  });

  describe('setSecurityReport', () => {
    it('should set security issues', () => {
      store.setSecurityReport(securityIssues, 'path');

      expect(store.securityReport).toEqual(parsedSecurityIssuesStore);
    });
  });

  describe('parseIssues', () => {
    it('should parse the received issues', () => {
      const codequality = MergeRequestStore.parseIssues(baseIssues, 'path')[0];
      expect(codequality.name).toEqual(baseIssues[0].check_name);
      expect(codequality.path).toEqual(baseIssues[0].location.path);
      expect(codequality.line).toEqual(baseIssues[0].location.lines.begin);

      const security = MergeRequestStore.parseIssues(securityIssues, 'path')[0];
      expect(security.name).toEqual(securityIssues[0].message);
      expect(security.path).toEqual(securityIssues[0].file);
    });
  });

  describe('isNothingToMergeState', () => {
    it('returns true when nothingToMerge', () => {
      store.state = stateKey.nothingToMerge;
      expect(store.isNothingToMergeState).toEqual(true);
    });

    it('returns false when not nothingToMerge', () => {
      store.state = 'state';
      expect(store.isNothingToMergeState).toEqual(false);
    });
  });

  describe('initDockerReport', () => {
    it('sets the defaults', () => {
      store.initDockerReport({ sast_container: { path: 'gl-sast-container.json' } });

      expect(store.sastContainer).toEqual({ path: 'gl-sast-container.json' });
      expect(store.dockerReport).toEqual({
        approved: [],
        unapproved: [],
        vulnerabilities: [],
      });
    });
  });

  describe('setDockerReport', () => {
    it('sets docker report with approved and unapproved vulnerabilities parsed', () => {
      store.setDockerReport(dockerReport);
      expect(store.dockerReport.vulnerabilities).toEqual(dockerReportParsed.vulnerabilities);
      expect(store.dockerReport.approved).toEqual(dockerReportParsed.approved);
      expect(store.dockerReport.unapproved).toEqual(dockerReportParsed.unapproved);
    });

    it('handles unaproved typo', () => {
      store.setDockerReport({
        vulnerabilities: [
          {
            vulnerability: 'CVE-2017-12944',
            namespace: 'debian:8',
            severity: 'Medium',
          },
        ],
        unaproved: ['CVE-2017-12944'],
      });

      expect(store.dockerReport.unapproved[0].vulnerability).toEqual('CVE-2017-12944');
    });
  });

  describe('parseDockerVulnerabilities', () => {
    it('parses docker report', () => {
      expect(
        MergeRequestStore.parseDockerVulnerabilities(dockerReport.vulnerabilities),
      ).toEqual(
        dockerReportParsed.vulnerabilities,
      );
    });
  });

  describe('initDastReport', () => {
    it('sets the defaults', () => {
      store.initDastReport({ dast: { path: 'dast.json' } });

      expect(store.dast).toEqual({ path: 'dast.json' });
      expect(store.dastReport).toEqual([]);
    });
  });

  describe('setDastReport', () => {
    it('parsed data and sets the report', () => {
      store.setDastReport(dast);

      expect(store.dastReport).toEqual(parsedDast);
    });
  });
});
