import RepoStore from '~/repo/stores/repo_store';

describe('RepoStore', () => {
  describe('setFileActivity', () => {
    const index = 10;

    it('calls setActiveFile', () => {
      const file = {
        url: '//url',
      };
      const openedFile = file;
      const activeFile = openedFile;
      activeFile.active = true;

      spyOn(RepoStore, 'setActiveFile');

      const returnValue = RepoStore.setFileActivity(file, openedFile, index);

      expect(RepoStore.setActiveFile).toHaveBeenCalledWith(activeFile, index);
      expect(returnValue).toEqual(activeFile);
    });

    it('does not call setActiveFile if file is not active', () => {
      const file = {
        url: '//url',
      };
      const openedFile = {
        url: '//other-url',
      };
      const activeFile = openedFile;
      activeFile.active = false;

      spyOn(RepoStore, 'setActiveFile');

      const returnValue = RepoStore.setFileActivity(file, openedFile, index);

      expect(RepoStore.setActiveFile).not.toHaveBeenCalled();
      expect(returnValue).toEqual(activeFile);
    });

    it('sets currentLine and reset hashToSet if hasToSet is set', () => {
      const file = {
        url: '//url',
      };
      const openedFile = file;
      const activeFile = openedFile;
      const hash = 'L10';
      activeFile.active = true;
      activeFile.currentLint = hash;
      RepoStore.hashToSet = hash;

      const returnValue = RepoStore.setFileActivity(file, openedFile, index);

      expect(returnValue).toEqual(activeFile);
      expect(RepoStore.hashToSet).toBeFalsy();
    });
  });
});
