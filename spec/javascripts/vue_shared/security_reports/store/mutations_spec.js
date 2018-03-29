import state from 'ee/vue_shared/security_reports/store/state';
import mutations from 'ee/vue_shared/security_reports/store/mutations';
import * as types from 'ee/vue_shared/security_reports/store/mutation_types';
import {
  sastIssues,
  sastIssuesBase,
  parsedSastIssuesHead,
  parsedSastBaseStore,
  dockerReport,
  dockerBaseReport,
  dockerNewIssues,
  dockerOnlyHeadParsed,
  dast,
  dastBase,
  parsedDastNewIssues,
  parsedDast,
  parsedSastIssuesStore,
} from '../mock_data';

describe('security reports mutations', () => {
  let stateCopy;

  beforeEach(() => {
    stateCopy = state();
  });

  describe('SET_HEAD_BLOB_PATH', () => {
    it('should set head blob path', () => {
      mutations[types.SET_HEAD_BLOB_PATH](stateCopy, 'head_blob_path');

      expect(stateCopy.blobPath.head).toEqual('head_blob_path');
    });
  });

  describe('SET_BASE_BLOB_PATH', () => {
    it('should set base blob path', () => {
      mutations[types.SET_BASE_BLOB_PATH](stateCopy, 'base_blob_path');

      expect(stateCopy.blobPath.base).toEqual('base_blob_path');
    });
  });

  describe('SET_SAST_HEAD_PATH', () => {
    it('should set sast head path', () => {
      mutations[types.SET_SAST_HEAD_PATH](stateCopy, 'sast_head_path');

      expect(stateCopy.sast.paths.head).toEqual('sast_head_path');
    });
  });

  describe('SET_SAST_BASE_PATH', () => {
    it('sets sast base path', () => {
      mutations[types.SET_SAST_BASE_PATH](stateCopy, 'sast_base_path');

      expect(stateCopy.sast.paths.base).toEqual('sast_base_path');
    });
  });

  describe('REQUEST_SAST_REPORTS', () => {
    it('should set sast loading flag to true', () => {
      mutations[types.REQUEST_SAST_REPORTS](stateCopy);

      expect(stateCopy.sast.isLoading).toEqual(true);
    });
  });

  describe('RECEIVE_SAST_REPORTS', () => {
    describe('with head and base', () => {
      it('should set new, fixed and all issues', () => {
        mutations[types.SET_BASE_BLOB_PATH](stateCopy, 'path');
        mutations[types.SET_HEAD_BLOB_PATH](stateCopy, 'path');

        mutations[types.RECEIVE_SAST_REPORTS](stateCopy, {
          head: sastIssues,
          base: sastIssuesBase,
        });

        expect(stateCopy.sast.isLoading).toEqual(false);
        expect(stateCopy.sast.newIssues).toEqual(parsedSastIssuesHead);
        expect(stateCopy.sast.resolvedIssues).toEqual(parsedSastBaseStore);
      });
    });

    describe('with head', () => {
      it('should set new issues', () => {
        mutations[types.SET_HEAD_BLOB_PATH](stateCopy, 'path');
        mutations[types.RECEIVE_SAST_REPORTS](stateCopy, {
          head: sastIssues,
        });

        expect(stateCopy.sast.isLoading).toEqual(false);
        expect(stateCopy.sast.newIssues).toEqual(parsedSastIssuesStore);
      });
    });
  });

  describe('RECEIVE_SAST_REPORTS_ERROR', () => {
    it('should set loading flag to false and error flag to true for sast', () => {
      mutations[types.RECEIVE_SAST_REPORTS_ERROR](stateCopy);
      expect(stateCopy.sast.isLoading).toEqual(false);
      expect(stateCopy.sast.hasError).toEqual(true);
    });
  });

  describe('SET_SAST_CONTAINER_HEAD_PATH', () => {
    it('should set sast container head path', () => {
      mutations[types.SET_SAST_CONTAINER_HEAD_PATH](stateCopy, 'head_path');

      expect(stateCopy.sastContainer.paths.head).toEqual('head_path');
    });
  });

  describe('SET_SAST_CONTAINER_BASE_PATH', () => {
    it('should set sast container base path', () => {
      mutations[types.SET_SAST_CONTAINER_BASE_PATH](stateCopy, 'base_path');

      expect(stateCopy.sastContainer.paths.base).toEqual('base_path');
    });
  });

  describe('REQUEST_SAST_CONTAINER_REPORTS', () => {
    it('should set sast container loading flag to true', () => {
      mutations[types.REQUEST_SAST_CONTAINER_REPORTS](stateCopy);

      expect(stateCopy.sastContainer.isLoading).toEqual(true);
    });
  });

  describe('RECEIVE_SAST_CONTAINER_REPORTS', () => {
    describe('with head and base', () => {
      it('should set new and resolved issues', () => {
        mutations[types.RECEIVE_SAST_CONTAINER_REPORTS](stateCopy, {
          head: dockerReport,
          base: dockerBaseReport,
        });

        expect(stateCopy.sastContainer.isLoading).toEqual(false);
        expect(stateCopy.sastContainer.newIssues).toEqual(dockerNewIssues);
        expect(stateCopy.sastContainer.resolvedIssues).toEqual([]);
      });
    });

    describe('with head', () => {
      it('should set new issues', () => {
        mutations[types.RECEIVE_SAST_CONTAINER_REPORTS](stateCopy, {
          head: dockerReport,
        });

        expect(stateCopy.sastContainer.isLoading).toEqual(false);
        expect(stateCopy.sastContainer.newIssues).toEqual(dockerOnlyHeadParsed);
      });
    });
  });

  describe('RECEIVE_SAST_CONTAINER_ERROR', () => {
    it('should set sast container loading flag to false and error flag to true', () => {
      mutations[types.RECEIVE_SAST_CONTAINER_ERROR](stateCopy);

      expect(stateCopy.sastContainer.isLoading).toEqual(false);
      expect(stateCopy.sastContainer.hasError).toEqual(true);
    });
  });

  describe('SET_DAST_HEAD_PATH', () => {
    it('should set dast head path', () => {
      mutations[types.SET_DAST_HEAD_PATH](stateCopy, 'head_path');

      expect(stateCopy.dast.paths.head).toEqual('head_path');
    });
  });

  describe('SET_DAST_BASE_PATH', () => {
    it('should set dast base path', () => {
      mutations[types.SET_DAST_BASE_PATH](stateCopy, 'base_path');

      expect(stateCopy.dast.paths.base).toEqual('base_path');
    });
  });

  describe('REQUEST_DAST_REPORTS', () => {
    it('should set dast loading flag to true', () => {
      mutations[types.REQUEST_DAST_REPORTS](stateCopy);

      expect(stateCopy.dast.isLoading).toEqual(true);
    });
  });

  describe('RECEIVE_DAST_REPORTS', () => {
    describe('with head and base', () => {
      it('sets new and resolved issues with the given data', () => {
        mutations[types.RECEIVE_DAST_REPORTS](stateCopy, {
          head: dast,
          base: dastBase,
        });

        expect(stateCopy.dast.isLoading).toEqual(false);
        expect(stateCopy.dast.newIssues).toEqual(parsedDastNewIssues);
        expect(stateCopy.dast.resolvedIssues).toEqual([]);
      });
    });

    describe('with head', () => {
      it('sets new  issues with the given data', () => {
        mutations[types.RECEIVE_DAST_REPORTS](stateCopy, {
          head: dast,
        });

        expect(stateCopy.dast.isLoading).toEqual(false);
        expect(stateCopy.dast.newIssues).toEqual(parsedDast);
      });
    });
  });

  describe('RECEIVE_DAST_ERROR', () => {
    it('should set dast loading flag to false and error flag to true', () => {
      mutations[types.RECEIVE_DAST_ERROR](stateCopy);

      expect(stateCopy.dast.isLoading).toEqual(false);
      expect(stateCopy.dast.hasError).toEqual(true);
    });
  });

  describe('SET_DEPENDENCY_SCANNING_HEAD_PATH', () => {
    it('should set dependency scanning head path', () => {
      mutations[types.SET_DEPENDENCY_SCANNING_HEAD_PATH](stateCopy, 'head_path');

      expect(stateCopy.dependencyScanning.paths.head).toEqual('head_path');
    });
  });

  describe('SET_DEPENDENCY_SCANNING_BASE_PATH', () => {
    it('should set dependency scanning base path', () => {
      mutations[types.SET_DEPENDENCY_SCANNING_BASE_PATH](stateCopy, 'base_path');

      expect(stateCopy.dependencyScanning.paths.base).toEqual('base_path');
    });
  });

  describe('REQUEST_DEPENDENCY_SCANNING_REPORTS', () => {
    it('should set dependency scanning loading flag to true', () => {
      mutations[types.REQUEST_DEPENDENCY_SCANNING_REPORTS](stateCopy);

      expect(stateCopy.dependencyScanning.isLoading).toEqual(true);
    });
  });

  describe('RECEIVE_DEPENDENCY_SCANNING_REPORTS', () => {
    describe('with head and base', () => {
      it('should set new, fixed and all issues', () => {
        mutations[types.SET_BASE_BLOB_PATH](stateCopy, 'path');
        mutations[types.SET_HEAD_BLOB_PATH](stateCopy, 'path');
        mutations[types.RECEIVE_DEPENDENCY_SCANNING_REPORTS](stateCopy, {
          head: sastIssues,
          base: sastIssuesBase,
        });

        expect(stateCopy.dependencyScanning.isLoading).toEqual(false);
        expect(stateCopy.dependencyScanning.newIssues).toEqual(parsedSastIssuesHead);
        expect(stateCopy.dependencyScanning.resolvedIssues).toEqual(parsedSastBaseStore);
      });
    });

    describe('with head', () => {
      it('should set new issues', () => {
        mutations[types.SET_HEAD_BLOB_PATH](stateCopy, 'path');
        mutations[types.RECEIVE_DEPENDENCY_SCANNING_REPORTS](stateCopy, {
          head: sastIssues,
        });
        expect(stateCopy.dependencyScanning.isLoading).toEqual(false);
        expect(stateCopy.dependencyScanning.newIssues).toEqual(parsedSastIssuesStore);
      });
    });
  });

  describe('RECEIVE_DEPENDENCY_SCANNING_ERROR', () => {
    it('should set dependency scanning loading flag to false and error flag to true', () => {
      mutations[types.RECEIVE_DEPENDENCY_SCANNING_ERROR](stateCopy);

      expect(stateCopy.dependencyScanning.isLoading).toEqual(false);
      expect(stateCopy.dependencyScanning.hasError).toEqual(true);
    });
  });
});
