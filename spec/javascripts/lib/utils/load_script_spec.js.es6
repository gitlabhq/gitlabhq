/* global ClassSpecHelper */

/*= require lib/utils/load_script */
/*= require class_spec_helper */

describe('LoadScript', () => {
  const global = window.gl || (window.gl = {});
  const LoadScript = global.LoadScript;

  it('should be defined in the global scope', () => {
    expect(LoadScript).toBeDefined();
  });

  describe('.load', () => {
    ClassSpecHelper.itShouldBeAStaticMethod(LoadScript, 'load');

    it('should reject if no source argument is provided', () => {
      spyOn(Promise, 'reject');
      LoadScript.load();
      expect(Promise.reject).toHaveBeenCalledWith('source url must be defined');
    });

    it('should reject if the script id already exists', () => {
      spyOn(Promise, 'reject');
      spyOn(document, 'querySelector').and.returnValue({});
      LoadScript.load('src.js', 'src-id');

      expect(Promise.reject).toHaveBeenCalledWith('script id already exists');
    });

    it('should return a promise on completion', () => {
      expect(LoadScript.load('src.js')).toEqual(jasmine.any(Promise));
    });

    it('should call appendScript when the promise is constructed', () => {
      spyOn(LoadScript, 'appendScript');
      LoadScript.load('src.js', 'src-id');

      expect(LoadScript.appendScript).toHaveBeenCalledWith('src.js', 'src-id', jasmine.any(Promise.resolve.constructor), jasmine.any(Promise.reject.constructor));
    });
  });

  describe('.appendScript', () => {
    beforeEach(() => {
      spyOn(document.body, 'appendChild');
    });

    ClassSpecHelper.itShouldBeAStaticMethod(LoadScript, 'appendScript');

    describe('when called', () => {
      let mockScriptTag;

      beforeEach(() => {
        mockScriptTag = {};
        spyOn(document, 'createElement').and.returnValue(mockScriptTag);
        LoadScript.appendScript('src.js', 'src-id', () => {}, () => {});
      });

      it('should create a script tag', () => {
        expect(document.createElement).toHaveBeenCalledWith('script');
      });

      it('should set the MIME type', () => {
        expect(mockScriptTag.type).toBe('text/javascript');
      });

      it('should set the script id', () => {
        expect(mockScriptTag.id).toBe('src-id');
      });

      it('should set an onload handler', () => {
        expect(mockScriptTag.onload).toEqual(jasmine.any(Function));
      });

      it('should set an onerror handler', () => {
        expect(mockScriptTag.onerror).toEqual(jasmine.any(Function));
      });

      it('should set the src attribute', () => {
        expect(mockScriptTag.src).toBe('src.js');
      });

      it('should append the script tag to the body element', () => {
        expect(document.body.appendChild).toHaveBeenCalledWith(mockScriptTag);
      });
    });

    it('should not set the script id if no id is provided', () => {
      const mockScriptTag = {};
      spyOn(document, 'createElement').and.returnValue(mockScriptTag);
      LoadScript.appendScript('src.js', undefined);
      expect(mockScriptTag.id).toBeUndefined();
    });
  });
});
