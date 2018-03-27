import projectImportGitlab from '~/projects/project_import_gitlab_project';

describe('Import Gitlab project', () => {
  let projectName;
  beforeEach(() => {
    projectName = 'project';
    window.history.pushState({}, null, `?path=${projectName}`);

    setFixtures(`
      <input class="js-path-name" />
    `);

    projectImportGitlab();
  });

  afterEach(() => {
    window.history.pushState({}, null, '');
  });

  describe('path name', () => {
    it('should fill in the project name derived from the previously filled project name', () => {
      expect(document.querySelector('.js-path-name').value).toEqual(projectName);
    });
  });
});
