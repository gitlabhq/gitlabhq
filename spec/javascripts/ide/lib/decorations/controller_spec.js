/* global monaco */
import monacoLoader from '~/ide/monaco_loader';
import editor from '~/ide/lib/editor';
import DecorationsController from '~/ide/lib/decorations/controller';
import Model from '~/ide/lib/common/model';
import { file } from '../../helpers';

describe('Multi-file editor library decorations controller', () => {
  let editorInstance;
  let controller;
  let model;

  beforeEach(done => {
    monacoLoader(['vs/editor/editor.main'], () => {
      editorInstance = editor.create(monaco);
      editorInstance.createInstance(document.createElement('div'));

      controller = new DecorationsController(editorInstance);
      model = new Model(monaco, file('path'));

      done();
    });
  });

  afterEach(() => {
    model.dispose();
    editorInstance.dispose();
    controller.dispose();
  });

  describe('getAllDecorationsForModel', () => {
    it('returns empty array when no decorations exist for model', () => {
      const decorations = controller.getAllDecorationsForModel(model);

      expect(decorations).toEqual([]);
    });

    it('returns decorations by model URL', () => {
      controller.addDecorations(model, 'key', [
        { decoration: 'decorationValue' },
      ]);

      const decorations = controller.getAllDecorationsForModel(model);

      expect(decorations[0]).toEqual({ decoration: 'decorationValue' });
    });
  });

  describe('addDecorations', () => {
    it('caches decorations in a new map', () => {
      controller.addDecorations(model, 'key', [
        { decoration: 'decorationValue' },
      ]);

      expect(controller.decorations.size).toBe(1);
    });

    it('does not create new cache model', () => {
      controller.addDecorations(model, 'key', [
        { decoration: 'decorationValue' },
      ]);
      controller.addDecorations(model, 'key', [
        { decoration: 'decorationValue2' },
      ]);

      expect(controller.decorations.size).toBe(1);
    });

    it('caches decorations by model URL', () => {
      controller.addDecorations(model, 'key', [
        { decoration: 'decorationValue' },
      ]);

      expect(controller.decorations.size).toBe(1);
      expect(controller.decorations.keys().next().value).toBe('path');
    });

    it('calls decorate method', () => {
      spyOn(controller, 'decorate');

      controller.addDecorations(model, 'key', [
        { decoration: 'decorationValue' },
      ]);

      expect(controller.decorate).toHaveBeenCalled();
    });
  });

  describe('decorate', () => {
    it('sets decorations on editor instance', () => {
      spyOn(controller.editor.instance, 'deltaDecorations');

      controller.decorate(model);

      expect(controller.editor.instance.deltaDecorations).toHaveBeenCalledWith(
        [],
        [],
      );
    });

    it('caches decorations', () => {
      spyOn(controller.editor.instance, 'deltaDecorations').and.returnValue([]);

      controller.decorate(model);

      expect(controller.editorDecorations.size).toBe(1);
    });

    it('caches decorations by model URL', () => {
      spyOn(controller.editor.instance, 'deltaDecorations').and.returnValue([]);

      controller.decorate(model);

      expect(controller.editorDecorations.keys().next().value).toBe('path');
    });
  });

  describe('dispose', () => {
    it('clears cached decorations', () => {
      controller.addDecorations(model, 'key', [
        { decoration: 'decorationValue' },
      ]);

      controller.dispose();

      expect(controller.decorations.size).toBe(0);
    });

    it('clears cached editorDecorations', () => {
      controller.addDecorations(model, 'key', [
        { decoration: 'decorationValue' },
      ]);

      controller.dispose();

      expect(controller.editorDecorations.size).toBe(0);
    });
  });
});
