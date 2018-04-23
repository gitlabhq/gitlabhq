/* global monaco */
import monacoLoader from '~/ide/monaco_loader';
import editor from '~/ide/lib/editor';
import ModelManager from '~/ide/lib/common/model_manager';
import DecorationsController from '~/ide/lib/decorations/controller';
import DirtyDiffController, { getDiffChangeType, getDecorator } from '~/ide/lib/diff/controller';
import { computeDiff } from '~/ide/lib/diff/diff';
import { file } from '../../helpers';

describe('Multi-file editor library dirty diff controller', () => {
  let editorInstance;
  let controller;
  let modelManager;
  let decorationsController;
  let model;

  beforeEach(done => {
    monacoLoader(['vs/editor/editor.main'], () => {
      editorInstance = editor.create(monaco);
      editorInstance.createInstance(document.createElement('div'));

      modelManager = new ModelManager(monaco);
      decorationsController = new DecorationsController(editorInstance);

      model = modelManager.addModel(file('path'));

      controller = new DirtyDiffController(modelManager, decorationsController);

      done();
    });
  });

  afterEach(() => {
    controller.dispose();
    model.dispose();
    decorationsController.dispose();
    editorInstance.dispose();
  });

  describe('getDiffChangeType', () => {
    ['added', 'removed', 'modified'].forEach(type => {
      it(`returns ${type}`, () => {
        const change = {
          [type]: true,
        };

        expect(getDiffChangeType(change)).toBe(type);
      });
    });
  });

  describe('getDecorator', () => {
    ['added', 'removed', 'modified'].forEach(type => {
      it(`returns with linesDecorationsClassName for ${type}`, () => {
        const change = {
          [type]: true,
        };

        expect(getDecorator(change).options.linesDecorationsClassName).toBe(
          `dirty-diff dirty-diff-${type}`,
        );
      });

      it('returns with line numbers', () => {
        const change = {
          lineNumber: 1,
          endLineNumber: 2,
          [type]: true,
        };

        const range = getDecorator(change).range;

        expect(range.startLineNumber).toBe(1);
        expect(range.endLineNumber).toBe(2);
        expect(range.startColumn).toBe(1);
        expect(range.endColumn).toBe(1);
      });
    });
  });

  describe('attachModel', () => {
    it('adds change event callback', () => {
      spyOn(model, 'onChange');

      controller.attachModel(model);

      expect(model.onChange).toHaveBeenCalled();
    });

    it('adds dispose event callback', () => {
      spyOn(model, 'onDispose');

      controller.attachModel(model);

      expect(model.onDispose).toHaveBeenCalled();
    });

    it('calls throttledComputeDiff on change', () => {
      spyOn(controller, 'throttledComputeDiff');

      controller.attachModel(model);

      model.getModel().setValue('123');

      expect(controller.throttledComputeDiff).toHaveBeenCalled();
    });

    it('caches model', () => {
      controller.attachModel(model);

      expect(controller.models.has(model.url)).toBe(true);
    });
  });

  describe('computeDiff', () => {
    it('posts to worker', () => {
      spyOn(controller.dirtyDiffWorker, 'postMessage');

      controller.computeDiff(model);

      expect(controller.dirtyDiffWorker.postMessage).toHaveBeenCalledWith({
        path: model.path,
        originalContent: '',
        newContent: '',
      });
    });
  });

  describe('reDecorate', () => {
    it('calls computeDiff when no decorations are cached', () => {
      spyOn(controller, 'computeDiff');

      controller.reDecorate(model);

      expect(controller.computeDiff).toHaveBeenCalledWith(model);
    });

    it('calls decorate when decorations are cached', () => {
      spyOn(controller.decorationsController, 'decorate');

      controller.decorationsController.decorations.set(model.url, 'test');

      controller.reDecorate(model);

      expect(controller.decorationsController.decorate).toHaveBeenCalledWith(model);
    });
  });

  describe('decorate', () => {
    it('adds decorations into decorations controller', () => {
      spyOn(controller.decorationsController, 'addDecorations');

      controller.decorate({ data: { changes: [], path: model.path } });

      expect(controller.decorationsController.addDecorations).toHaveBeenCalledWith(
        model,
        'dirtyDiff',
        jasmine.anything(),
      );
    });

    it('adds decorations into editor', () => {
      const spy = spyOn(controller.decorationsController.editor.instance, 'deltaDecorations');

      controller.decorate({
        data: { changes: computeDiff('123', '1234'), path: model.path },
      });

      expect(spy).toHaveBeenCalledWith(
        [],
        [
          {
            range: new monaco.Range(1, 1, 1, 1),
            options: {
              isWholeLine: true,
              linesDecorationsClassName: 'dirty-diff dirty-diff-modified',
            },
          },
        ],
      );
    });
  });

  describe('dispose', () => {
    it('calls disposable dispose', () => {
      spyOn(controller.disposable, 'dispose').and.callThrough();

      controller.dispose();

      expect(controller.disposable.dispose).toHaveBeenCalled();
    });

    it('terminates worker', () => {
      spyOn(controller.dirtyDiffWorker, 'terminate').and.callThrough();

      controller.dispose();

      expect(controller.dirtyDiffWorker.terminate).toHaveBeenCalled();
    });

    it('removes worker event listener', () => {
      spyOn(controller.dirtyDiffWorker, 'removeEventListener').and.callThrough();

      controller.dispose();

      expect(controller.dirtyDiffWorker.removeEventListener).toHaveBeenCalledWith(
        'message',
        jasmine.anything(),
      );
    });

    it('clears cached models', () => {
      controller.attachModel(model);

      model.dispose();

      expect(controller.models.size).toBe(0);
    });
  });
});
