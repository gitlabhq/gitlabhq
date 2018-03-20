import Disposable from 'ee/ide/lib/common/disposable';

describe('Multi-file editor library disposable class', () => {
  let instance;
  let disposableClass;

  beforeEach(() => {
    instance = new Disposable();

    disposableClass = {
      dispose: jasmine.createSpy('dispose'),
    };
  });

  afterEach(() => {
    instance.dispose();
  });

  describe('add', () => {
    it('adds disposable classes', () => {
      instance.add(disposableClass);

      expect(instance.disposers.size).toBe(1);
    });
  });

  describe('dispose', () => {
    beforeEach(() => {
      instance.add(disposableClass);
    });

    it('calls dispose on all cached disposers', () => {
      instance.dispose();

      expect(disposableClass.dispose).toHaveBeenCalled();
    });

    it('clears cached disposers', () => {
      instance.dispose();

      expect(instance.disposers.size).toBe(0);
    });
  });
});
