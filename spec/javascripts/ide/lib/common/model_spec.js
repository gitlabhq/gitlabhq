/* global monaco */
import eventHub from '~/ide/eventhub';
import monacoLoader from '~/ide/monaco_loader';
import Model from '~/ide/lib/common/model';
import { file } from '../../helpers';

describe('Multi-file editor library model', () => {
  let model;

  beforeEach(done => {
    spyOn(eventHub, '$on').and.callThrough();

    monacoLoader(['vs/editor/editor.main'], () => {
      const f = file('path');
      f.mrChange = { diff: 'ABC' };
      f.baseRaw = 'test';
      model = new Model(monaco, f);

      done();
    });
  });

  afterEach(() => {
    model.dispose();
  });

  it('creates original model & base model & new model', () => {
    expect(model.originalModel).not.toBeNull();
    expect(model.model).not.toBeNull();
    expect(model.baseModel).not.toBeNull();
  });

  it('creates model with head file to compare against', () => {
    const f = file('path');
    model.dispose();

    model = new Model(monaco, f, {
      ...f,
      content: '123 testing',
    });

    expect(model.head).not.toBeNull();
    expect(model.getOriginalModel().getValue()).toBe('123 testing');
  });

  it('adds eventHub listener', () => {
    expect(eventHub.$on).toHaveBeenCalledWith(
      `editor.update.model.dispose.${model.file.key}`,
      jasmine.anything(),
    );
  });

  describe('path', () => {
    it('returns file path', () => {
      expect(model.path).toBe(model.file.key);
    });
  });

  describe('getModel', () => {
    it('returns model', () => {
      expect(model.getModel()).toBe(model.model);
    });
  });

  describe('getOriginalModel', () => {
    it('returns original model', () => {
      expect(model.getOriginalModel()).toBe(model.originalModel);
    });
  });

  describe('getBaseModel', () => {
    it('returns base model', () => {
      expect(model.getBaseModel()).toBe(model.baseModel);
    });
  });

  describe('setValue', () => {
    it('updates models value', () => {
      model.setValue('testing 123');

      expect(model.getModel().getValue()).toBe('testing 123');
    });
  });

  describe('onChange', () => {
    it('calls callback on change', done => {
      const spy = jasmine.createSpy();
      model.onChange(spy);

      model.getModel().setValue('123');

      setTimeout(() => {
        expect(spy).toHaveBeenCalledWith(model, jasmine.anything());
        done();
      });
    });
  });

  describe('dispose', () => {
    it('calls disposable dispose', () => {
      spyOn(model.disposable, 'dispose').and.callThrough();

      model.dispose();

      expect(model.disposable.dispose).toHaveBeenCalled();
    });

    it('clears events', () => {
      model.onChange(() => {});

      expect(model.events.size).toBe(1);

      model.dispose();

      expect(model.events.size).toBe(0);
    });

    it('removes eventHub listener', () => {
      spyOn(eventHub, '$off').and.callThrough();

      model.dispose();

      expect(eventHub.$off).toHaveBeenCalledWith(
        `editor.update.model.dispose.${model.file.key}`,
        jasmine.anything(),
      );
    });

    it('calls onDispose callback', () => {
      const disposeSpy = jasmine.createSpy();

      model.onDispose(disposeSpy);

      model.dispose();

      expect(disposeSpy).toHaveBeenCalled();
    });
  });
});
