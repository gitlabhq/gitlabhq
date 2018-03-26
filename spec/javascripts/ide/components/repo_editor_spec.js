import Vue from 'vue';
import store from '~/ide/stores';
import repoEditor from '~/ide/components/repo_editor.vue';
import monacoLoader from '~/ide/monaco_loader';
import Editor from '~/ide/lib/editor';
import { createComponentWithStore } from '../../helpers/vue_mount_component_helper';
import { file, resetStore } from '../helpers';

describe('RepoEditor', () => {
  let vm;

  beforeEach(done => {
    const f = file();
    const RepoEditor = Vue.extend(repoEditor);

    vm = createComponentWithStore(RepoEditor, store, {
      file: f,
    });

    f.active = true;
    f.tempFile = true;
    f.html = 'testing';
    vm.$store.state.openFiles.push(f);
    vm.$store.state.entries[f.path] = f;
    vm.monaco = true;

    vm.$mount();

    monacoLoader(['vs/editor/editor.main'], () => {
      setTimeout(done, 0);
    });
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);

    Editor.editorInstance.modelManager.dispose();
  });

  it('renders an ide container', done => {
    Vue.nextTick(() => {
      expect(vm.shouldHideEditor).toBeFalsy();

      done();
    });
  });

  describe('when open file is binary and not raw', () => {
    beforeEach(done => {
      vm.file.binary = true;

      vm.$nextTick(done);
    });

    it('does not render the IDE', () => {
      expect(vm.shouldHideEditor).toBeTruthy();
    });

    it('shows activeFile html', () => {
      expect(vm.$el.textContent).toContain('testing');
    });
  });

  describe('createEditorInstance', () => {
    it('calls createInstance when viewer is editor', done => {
      spyOn(vm.editor, 'createInstance');

      vm.createEditorInstance();

      vm.$nextTick(() => {
        expect(vm.editor.createInstance).toHaveBeenCalled();

        done();
      });
    });

    it('calls createDiffInstance when viewer is diff', done => {
      vm.$store.state.viewer = 'diff';

      spyOn(vm.editor, 'createDiffInstance');

      vm.createEditorInstance();

      vm.$nextTick(() => {
        expect(vm.editor.createDiffInstance).toHaveBeenCalled();

        done();
      });
    });

    it('calls createDiffInstance when viewer is a merge request diff', done => {
      vm.$store.state.viewer = 'mrdiff';

      spyOn(vm.editor, 'createDiffInstance');

      vm.createEditorInstance();

      vm.$nextTick(() => {
        expect(vm.editor.createDiffInstance).toHaveBeenCalled();

        done();
      });
    });
  });

  describe('setupEditor', () => {
    it('creates new model', () => {
      spyOn(vm.editor, 'createModel').and.callThrough();

      Editor.editorInstance.modelManager.dispose();

      vm.setupEditor();

      expect(vm.editor.createModel).toHaveBeenCalledWith(vm.file);
      expect(vm.model).not.toBeNull();
    });

    it('attaches model to editor', () => {
      spyOn(vm.editor, 'attachModel').and.callThrough();

      Editor.editorInstance.modelManager.dispose();

      vm.setupEditor();

      expect(vm.editor.attachModel).toHaveBeenCalledWith(vm.model);
    });

    it('adds callback methods', () => {
      spyOn(vm.editor, 'onPositionChange').and.callThrough();

      Editor.editorInstance.modelManager.dispose();

      vm.setupEditor();

      expect(vm.editor.onPositionChange).toHaveBeenCalled();
      expect(vm.model.events.size).toBe(1);
    });

    it('updates state when model content changed', done => {
      vm.model.setValue('testing 123');

      setTimeout(() => {
        expect(vm.file.content).toBe('testing 123');

        done();
      });
    });
  });

  describe('setup editor for merge request viewing', () => {
    beforeEach(done => {
      vm.$destroy();

      resetStore(vm.$store);

      Editor.editorInstance.modelManager.dispose();

      const f = file();
      const RepoEditor = Vue.extend(repoEditor);

      vm = createComponentWithStore(RepoEditor, store, {
        file: f,
      });

      f.active = true;
      f.tempFile = true;
      f.html = 'testing';
      f.mrChange = { diff: 'ABC' };
      f.baseRaw = 'testing';
      f.content = 'test';
      vm.$store.state.openFiles.push(f);
      vm.$store.state.entries[f.path] = f;

      vm.$store.state.viewer = 'mrdiff';

      vm.monaco = true;

      vm.$mount();

      monacoLoader(['vs/editor/editor.main'], () => {
        setTimeout(done, 0);
      });
    });

    it('attaches merge request model to editor when merge request diff', () => {
      spyOn(vm.editor, 'attachMergeRequestModel').and.callThrough();

      vm.setupEditor();

      expect(vm.editor.attachMergeRequestModel).toHaveBeenCalledWith(vm.model);
    });
  });
});
