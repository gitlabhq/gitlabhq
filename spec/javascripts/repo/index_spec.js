import Tabs from '~/repo/repo_tabs';
import Sidebar from '~/repo/repo_sidebar';
import Editor from '~/repo/repo_editor';
import FileButtons from '~/repo/repo_file_buttons';
import EditButton from '~/repo/repo_edit_button';
import BinaryViewer from '~/repo/repo_binary_viewer';
import CommitSection from '~/repo/repo_commit_section';
import Service from '~/repo/repo_service';
import Store from '~/repo/repo_store';
import Helper from '~/repo/repo_helper';

describe('initRepo', () => {
  const url = 'url';

  it('should select all elements, set store service and url, init all needed classes and getContent', () => {
    spyOn(Helper, 'getContent');
    spyOn(document, 'getElementById').and.callFake((selector) => {
      const element = document.createElement('div');

      if (selector === 'ide') element.dataset.url = url;

      return element;
    });

    require('~/repo/index'); // eslint-disable-line global-require

    expect(document.getElementById).toHaveBeenCalledWith('ide');
    expect(document.getElementById).toHaveBeenCalledWith('tabs');
    expect(document.getElementById).toHaveBeenCalledWith('sidebar');
    expect(document.getElementById).toHaveBeenCalledWith('repo-file-buttons');
    expect(document.getElementById).toHaveBeenCalledWith('editable-mode');
    expect(document.getElementById).toHaveBeenCalledWith('commit-area');
    expect(document.getElementById).toHaveBeenCalledWith('binary-viewer');
    expect(Store.service).toBe(Service);
    expect(Store.service.url).toBe(url);
    expect(Store.tabs instanceof Tabs).toBe(true);
    expect(Store.sidebar instanceof Sidebar).toBe(true);
    expect(Store.editor instanceof Editor).toBe(true);
    expect(Store.buttons instanceof FileButtons).toBe(true);
    expect(Store.editButton instanceof EditButton).toBe(true);
    expect(Store.commitSection instanceof CommitSection).toBe(true);
    expect(Store.binaryViewer instanceof BinaryViewer).toBe(true);
    expect(Helper.getContent).toHaveBeenCalled();
  });
});
