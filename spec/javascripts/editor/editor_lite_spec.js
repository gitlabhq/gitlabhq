import { editor as monacoEditor, Uri } from 'monaco-editor';
import Editor from '~/editor/editor_lite';

describe('Base editor', () => {
  let editorEl;
  let editor;
  const blobContent = 'Foo Bar';
  const blobPath = 'test.md';
  const uri = new Uri('gitlab', false, blobPath);
  const fakeModel = { foo: 'bar' };

  beforeEach(() => {
    setFixtures('<div id="editor" data-editor-loading></div>');
    editorEl = document.getElementById('editor');
    editor = new Editor();
  });

  afterEach(() => {
    editor.dispose();
    editorEl.remove();
  });

  it('initializes Editor with basic properties', () => {
    expect(editor).toBeDefined();
    expect(editor.editorEl).toBe(null);
    expect(editor.blobContent).toEqual('');
    expect(editor.blobPath).toEqual('');
  });

  it('removes `editor-loading` data attribute from the target DOM element', () => {
    editor.createInstance({ el: editorEl });

    expect(editorEl.dataset.editorLoading).toBeUndefined();
  });

  describe('instance of the Editor', () => {
    let modelSpy;
    let instanceSpy;
    let setModel;
    let dispose;

    beforeEach(() => {
      setModel = jasmine.createSpy();
      dispose = jasmine.createSpy();
      modelSpy = spyOn(monacoEditor, 'createModel').and.returnValue(fakeModel);
      instanceSpy = spyOn(monacoEditor, 'create').and.returnValue({
        setModel,
        dispose,
      });
    });

    it('does nothing if no dom element is supplied', () => {
      editor.createInstance();

      expect(editor.editorEl).toBe(null);
      expect(editor.blobContent).toEqual('');
      expect(editor.blobPath).toEqual('');

      expect(modelSpy).not.toHaveBeenCalled();
      expect(instanceSpy).not.toHaveBeenCalled();
      expect(setModel).not.toHaveBeenCalled();
    });

    it('creates model to be supplied to Monaco editor', () => {
      editor.createInstance({ el: editorEl, blobPath, blobContent });

      expect(modelSpy).toHaveBeenCalledWith(blobContent, undefined, uri);
      expect(setModel).toHaveBeenCalledWith(fakeModel);
    });

    it('initializes the instance on a supplied DOM node', () => {
      editor.createInstance({ el: editorEl });

      expect(editor.editorEl).not.toBe(null);
      expect(instanceSpy).toHaveBeenCalledWith(editorEl, jasmine.anything());
    });
  });

  describe('implementation', () => {
    beforeEach(() => {
      editor.createInstance({ el: editorEl, blobPath, blobContent });
    });

    afterEach(() => {
      editor.model.dispose();
    });

    it('correctly proxies value from the model', () => {
      expect(editor.getValue()).toEqual(blobContent);
    });

    it('is capable of changing the language of the model', () => {
      const blobRenamedPath = 'test.js';

      expect(editor.model.getLanguageIdentifier().language).toEqual('markdown');
      editor.updateModelLanguage(blobRenamedPath);

      expect(editor.model.getLanguageIdentifier().language).toEqual('javascript');
    });

    it('falls back to plaintext if there is no language associated with an extension', () => {
      const blobRenamedPath = 'test.myext';
      const spy = spyOn(console, 'error');

      editor.updateModelLanguage(blobRenamedPath);

      expect(spy).not.toHaveBeenCalled();
      expect(editor.model.getLanguageIdentifier().language).toEqual('plaintext');
    });
  });
});
