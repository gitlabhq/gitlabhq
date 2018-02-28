import axios from 'axios';
import RepoService from '~/repo/services/repo_service';
import RepoStore from '~/repo/stores/repo_store';
import Api from '~/api';

describe('RepoService', () => {
  it('has default json format param', () => {
    expect(RepoService.options.params.format).toBe('json');
  });

  describe('buildParams', () => {
    let newParams;
    const url = 'url';

    beforeEach(() => {
      newParams = {};

      spyOn(Object, 'assign').and.returnValue(newParams);
    });

    it('clones params', () => {
      const params = RepoService.buildParams(url);

      expect(Object.assign).toHaveBeenCalledWith({}, RepoService.options.params);

      expect(params).toBe(newParams);
    });

    it('sets and returns viewer params to richif urlIsRichBlob is true', () => {
      spyOn(RepoService, 'urlIsRichBlob').and.returnValue(true);

      const params = RepoService.buildParams(url);

      expect(params.viewer).toEqual('rich');
    });

    it('returns params urlIsRichBlob is false', () => {
      spyOn(RepoService, 'urlIsRichBlob').and.returnValue(false);

      const params = RepoService.buildParams(url);

      expect(params.viewer).toBeUndefined();
    });

    it('calls urlIsRichBlob with the objects url prop if no url arg is provided', () => {
      spyOn(RepoService, 'urlIsRichBlob');
      RepoService.url = url;

      RepoService.buildParams();

      expect(RepoService.urlIsRichBlob).toHaveBeenCalledWith(url);
    });
  });

  describe('urlIsRichBlob', () => {
    it('returns true for md extension', () => {
      const isRichBlob = RepoService.urlIsRichBlob('url.md');

      expect(isRichBlob).toBeTruthy();
    });

    it('returns false for js extension', () => {
      const isRichBlob = RepoService.urlIsRichBlob('url.js');

      expect(isRichBlob).toBeFalsy();
    });
  });

  describe('getContent', () => {
    const params = {};
    const url = 'url';
    const requestPromise = Promise.resolve();

    beforeEach(() => {
      spyOn(RepoService, 'buildParams').and.returnValue(params);
      spyOn(axios, 'get').and.returnValue(requestPromise);
    });

    it('calls buildParams and axios.get', () => {
      const request = RepoService.getContent(url);

      expect(RepoService.buildParams).toHaveBeenCalledWith(url);
      expect(axios.get).toHaveBeenCalledWith(url, {
        params,
      });
      expect(request).toBe(requestPromise);
    });

    it('uses object url prop if no url arg is provided', () => {
      RepoService.url = url;

      RepoService.getContent();

      expect(axios.get).toHaveBeenCalledWith(url, {
        params,
      });
    });
  });

  describe('getBase64Content', () => {
    const url = 'url';
    const response = { data: 'data' };

    beforeEach(() => {
      spyOn(RepoService, 'bufferToBase64');
      spyOn(axios, 'get').and.returnValue(Promise.resolve(response));
    });

    it('calls axios.get and bufferToBase64 on completion', (done) => {
      const request = RepoService.getBase64Content(url);

      expect(axios.get).toHaveBeenCalledWith(url, {
        responseType: 'arraybuffer',
      });
      expect(request).toEqual(jasmine.any(Promise));

      request.then(() => {
        expect(RepoService.bufferToBase64).toHaveBeenCalledWith(response.data);
        done();
      }).catch(done.fail);
    });
  });

  describe('commitFiles', () => {
    it('calls commitMultiple and .then commitFlash', (done) => {
      const projectId = 'projectId';
      const payload = {};
      RepoStore.projectId = projectId;

      spyOn(Api, 'commitMultiple').and.returnValue(Promise.resolve());
      spyOn(RepoService, 'commitFlash');

      const apiPromise = RepoService.commitFiles(payload);

      expect(Api.commitMultiple).toHaveBeenCalledWith(projectId, payload);

      apiPromise.then(() => {
        expect(RepoService.commitFlash).toHaveBeenCalled();
        done();
      }).catch(done.fail);
    });
  });

  describe('commitFlash', () => {
    it('calls Flash with data.message', () => {
      const data = {
        message: 'message',
      };
      spyOn(window, 'Flash');

      RepoService.commitFlash(data);

      expect(window.Flash).toHaveBeenCalledWith(data.message);
    });

    it('calls Flash with success string if short_id and stats', () => {
      const data = {
        short_id: 'short_id',
        stats: {
          additions: '4',
          deletions: '5',
        },
      };
      spyOn(window, 'Flash');

      RepoService.commitFlash(data);

      expect(window.Flash).toHaveBeenCalledWith(`Your changes have been committed. Commit ${data.short_id} with ${data.stats.additions} additions, ${data.stats.deletions} deletions.`, 'notice');
    });
  });
});
