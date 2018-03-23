import $ from 'jquery';
import projectNew from '~/projects/project_new';

describe('New Project', () => {
  let $projectImportUrl;
  let $projectPath;

  beforeEach(() => {
    setFixtures(`
      <div class='toggle-import-form'>
        <div class='import-url-data'>
          <input id="project_import_url" />
          <input id="project_path" />
        </div>
      </div>
    `);

    $projectImportUrl = $('#project_import_url');
    $projectPath = $('#project_path');
  });

  describe('deriveProjectPathFromUrl', () => {
    const dummyImportUrl = `${gl.TEST_HOST}/dummy/import/url.git`;

    beforeEach(() => {
      projectNew.bindEvents();
      $projectPath.val('').keyup().val(dummyImportUrl);
    });

    it('does not change project path for disabled $projectImportUrl', () => {
      $projectImportUrl.prop('disabled', true);

      projectNew.deriveProjectPathFromUrl($projectImportUrl);

      expect($projectPath.val()).toEqual(dummyImportUrl);
    });

    describe('for enabled $projectImportUrl', () => {
      beforeEach(() => {
        $projectImportUrl.prop('disabled', false);
      });

      it('does not change project path if it is set by user', () => {
        $projectPath.keyup();

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.val()).toEqual(dummyImportUrl);
      });

      it('does not change project path for empty $projectImportUrl', () => {
        $projectImportUrl.val('');

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.val()).toEqual(dummyImportUrl);
      });

      it('does not change project path for whitespace $projectImportUrl', () => {
        $projectImportUrl.val('   ');

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.val()).toEqual(dummyImportUrl);
      });

      it('does not change project path for $projectImportUrl without slashes', () => {
        $projectImportUrl.val('has-no-slash');

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.val()).toEqual(dummyImportUrl);
      });

      it('changes project path to last $projectImportUrl component', () => {
        $projectImportUrl.val('/this/is/last');

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.val()).toEqual('last');
      });

      it('ignores trailing slashes in $projectImportUrl', () => {
        $projectImportUrl.val('/has/trailing/slash/');

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.val()).toEqual('slash');
      });

      it('ignores fragment identifier in $projectImportUrl', () => {
        $projectImportUrl.val('/this/has/a#fragment-identifier/');

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.val()).toEqual('a');
      });

      it('ignores query string in $projectImportUrl', () => {
        $projectImportUrl.val('/url/with?query=string');

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.val()).toEqual('with');
      });

      it('ignores trailing .git in $projectImportUrl', () => {
        $projectImportUrl.val('/repository.git');

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.val()).toEqual('repository');
      });

      it('changes project path for HTTPS URL in $projectImportUrl', () => {
        $projectImportUrl.val('https://username:password@gitlab.company.com/group/project.git');

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.val()).toEqual('project');
      });

      it('changes project path for SSH URL in $projectImportUrl', () => {
        $projectImportUrl.val('git@gitlab.com:gitlab-org/gitlab-ce.git');

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.val()).toEqual('gitlab-ce');
      });
    });
  });
});
