import store from '~/repo/stores';
import service from '~/repo/services';
import { file } from '../../helpers';

describe('Multi-file store file actions', () => {
  describe('closeFile', () => {

  });

  describe('setFileActive', () => {

  });

  describe('getFileData', () => {

  });

  describe('getRawFileData', () => {
    let tmpFile;

    beforeEach(() => {
      spyOn(service, 'getRawFileData').and.returnValue(Promise.resolve('raw'));

      tmpFile = file();
    });

    it('calls getRawFileData service method', (done) => {
      store.dispatch('getRawFileData', tmpFile)
        .then(() => {
          expect(service.getRawFileData).toHaveBeenCalledWith(tmpFile);

          done();
        }).catch(done.fail);
    });

    it('updates file raw data', (done) => {
      store.dispatch('getRawFileData', tmpFile)
        .then(() => {
          expect(tmpFile.raw).toBe('raw');

          done();
        }).catch(done.fail);
    });
  });

  describe('changeFileContent', () => {
    let tmpFile;

    beforeEach(() => {
      tmpFile = file();
    });

    it('updates file content', (done) => {
      store.dispatch('changeFileContent', {
        file: tmpFile,
        content: 'content',
      })
      .then(() => {
        expect(tmpFile.content).toBe('content');

        done();
      }).catch(done.fail);
    });
  });

  describe('createTempFile', () => {

  });
});
