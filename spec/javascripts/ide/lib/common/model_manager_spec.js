/* global monaco */
import monacoLoader from 'ee/ide/monaco_loader';
import ModelManager from 'ee/ide/lib/common/model_manager';
import { file } from '../../helpers';

describe('Multi-file editor library model manager', () => {
  let instance;

  beforeEach((done) => {
    monacoLoader(['vs/editor/editor.main'], () => {
      instance = new ModelManager(monaco);

      done();
    });
  });

  afterEach(() => {
    instance.dispose();
  });

  describe('addModel', () => {
    it('caches model', () => {
      instance.addModel(file());

      expect(instance.models.size).toBe(1);
    });

    it('caches model by file path', () => {
      instance.addModel(file('path-name'));

      expect(instance.models.keys().next().value).toBe('path-name');
    });

    it('adds model into disposable', () => {
      spyOn(instance.disposable, 'add').and.callThrough();

      instance.addModel(file());

      expect(instance.disposable.add).toHaveBeenCalled();
    });

    it('returns cached model', () => {
      spyOn(instance.models, 'get').and.callThrough();

      instance.addModel(file());
      instance.addModel(file());

      expect(instance.models.get).toHaveBeenCalled();
    });
  });

  describe('hasCachedModel', () => {
    it('returns false when no models exist', () => {
      expect(instance.hasCachedModel('path')).toBeFalsy();
    });

    it('returns true when model exists', () => {
      instance.addModel(file('path-name'));

      expect(instance.hasCachedModel('path-name')).toBeTruthy();
    });
  });

  describe('getModel', () => {
    it('returns cached model', () => {
      instance.addModel(file('path-name'));

      expect(instance.getModel('path-name')).not.toBeNull();
    });
  });

  describe('dispose', () => {
    it('clears cached models', () => {
      instance.addModel(file());

      instance.dispose();

      expect(instance.models.size).toBe(0);
    });

    it('calls disposable dispose', () => {
      spyOn(instance.disposable, 'dispose').and.callThrough();

      instance.dispose();

      expect(instance.disposable.dispose).toHaveBeenCalled();
    });
  });
});
