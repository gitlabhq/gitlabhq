import Vue from 'vue';
import repoEditor from '~/repo/repo_editor';
import RepoStore from '~/repo/repo_store';

describe('RepoEditor', () => {
  function createComponent() {
    const RepoEditor = Vue.extend(repoEditor);

    return new RepoEditor().$mount();
  }

  it('renders an ide container', () => {
    const monacoInstance = jasmine.createSpyObj('monacoInstance', ['onMouseUp', 'onKeyUp', 'setModel']);
    const monaco = {
      editor: jasmine.createSpyObj('editor', ['create']),
    };
    RepoStore.monaco = monaco;

    monaco.editor.create.and.returnValue(monacoInstance);
    spyOn(repoEditor.watch, 'blobRaw');

    const vm = createComponent();

    expect(vm.$el.id).toEqual('ide');
  });
});
