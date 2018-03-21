import MergeRequestStore from 'ee/vue_merge_request_widget/stores/mr_widget_store';
import { stateKey } from '~/vue_merge_request_widget/stores/state_maps';
import mockData, {
  headIssues,
  baseIssues,
  parsedBaseIssues,
  parsedHeadIssues,
} from '../mock_data';
import {
  sastIssues,
  sastIssuesBase,
  parsedSastBaseStore,
  parsedSastIssuesHead,
  parsedSastIssuesStore,
  allIssuesParsed,
  dockerReport,
  dockerReportParsed,
  dast,
  parsedDast,
} from '../../vue_shared/security_reports/mock_data';

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
    it('should set security issues with head', () => {
      store.setSecurityReport({ head: sastIssues, headBlobPath: 'path' });
      expect(store.securityReport.newIssues).toEqual(parsedSastIssuesStore);
    });

    it('should set security issues with head and base', () => {
      store.setSecurityReport({
        head: sastIssues,
        headBlobPath: 'path',
        base: sastIssuesBase,
        baseBlobPath: 'path',
      });

      expect(store.securityReport.newIssues).toEqual(parsedSastIssuesHead);
      expect(store.securityReport.resolvedIssues).toEqual(parsedSastBaseStore);
      expect(store.securityReport.allIssues).toEqual(allIssuesParsed);
    });
  });

  describe('setDependencyScanningReport', () => {
    it('should set security issues with head', () => {
      store.setDependencyScanningReport({ head: sastIssues, headBlobPath: 'path' });
      expect(store.dependencyScanningReport.newIssues).toEqual(parsedSastIssuesStore);
    });

    it('should set security issues with head and base', () => {
      store.setDependencyScanningReport({
        head: sastIssues,
        headBlobPath: 'path',
        base: sastIssuesBase,
        baseBlobPath: 'path',
      });

      expect(store.dependencyScanningReport.newIssues).toEqual(parsedSastIssuesHead);
      expect(store.dependencyScanningReport.resolvedIssues).toEqual(parsedSastBaseStore);
      expect(store.dependencyScanningReport.allIssues).toEqual(allIssuesParsed);
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
