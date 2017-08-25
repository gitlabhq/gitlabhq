import RepoHelper from '~/repo/helpers/repo_helper';
import Store from '~/repo/stores/repo_store';

describe('RepoHelper', () => {
  describe('getFileLastCommitInfo', () => {
    beforeEach(() => {
      Store.files = [{
        name: 'file1.txt',
        lastCommitHash: '1a2b3c4d',
        lastCommitMessage: 'Initial Commit',
        lastCommitUpdate: '2012-01-08T13:20:20.000+02:00',
        lastCommitUrl: '/gitlab-org/gitlab-ce/commit/1a2b3c4d',
      }, {
        name: 'file2.js',
        lastCommitHash: '1a2b3c4d',
        lastCommitMessage: 'Initial Commit',
        lastCommitUpdate: '2012-01-08T13:20:20.000+02:00',
        lastCommitUrl: '/gitlab-org/gitlab-ce/commit/1a2b3c4d',
      }];
    });

    describe('filename matches store files', () => {
      it('returns lastCommit', () => {
        const lastCommit = RepoHelper.getFileLastCommitInfo(Store.files[0].name);

        expect(lastCommit.hash).toEqual(Store.files[0].lastCommitHash);
        expect(lastCommit.message).toEqual(Store.files[0].lastCommitMessage);
        expect(lastCommit.update).toEqual(Store.files[0].lastCommitUpdate);
        expect(lastCommit.url).toEqual(Store.files[0].lastCommitUrl);
      });
    });

    describe('filename does not match store files', () => {
      it('returns empty properties', () => {
        const lastCommit = RepoHelper.getFileLastCommitInfo('file3.md');

        expect(lastCommit.hash).toEqual('');
        expect(lastCommit.message).toEqual('');
        expect(lastCommit.update).toEqual('');
        expect(lastCommit.url).toEqual('');
      });
    });
  });

  describe('serializeBlob', () => {
    let simpleBlob;
    const blob = {
      last_commit: {
        message: 'message',
        id: 'id',
        committed_date: 'date',
      },
    };

    beforeEach(() => {
      spyOn(RepoHelper, 'serializeRepoEntity').and.callFake(() => ({}));
      simpleBlob = RepoHelper.serializeBlob(blob);
    });

    it('serializes lastCommitMessage', () => {
      expect(simpleBlob.lastCommitMessage).toEqual(blob.last_commit.message);
    });

    it('serializes lastCommitHash', () => {
      expect(simpleBlob.lastCommitHash).toEqual(blob.last_commit.id);
    });

    it('serializes lastCommitUpdate', () => {
      expect(simpleBlob.lastCommitUpdate).toEqual(blob.last_commit.committed_date);
    });

    it('sets blob loading to false', () => {
      expect(simpleBlob.loading).toEqual(false);
    });
  });
});
