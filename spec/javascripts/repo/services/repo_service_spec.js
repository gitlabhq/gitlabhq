import axios from 'axios';
import RepoService from '~/repo/services/repo_service';

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
});
