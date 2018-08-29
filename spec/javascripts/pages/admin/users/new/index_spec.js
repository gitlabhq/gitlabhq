import $ from 'jquery';
import UserInternalRegexHandler from '~/pages/admin/users/new/index';

describe('UserInternalRegexHandler', () => {
  const FIXTURE = 'admin/users/new_with_internal_user_regex.html.raw';
  let $userExternal;
  let $userEmail;
  let $warningMessage;

  preloadFixtures(FIXTURE);

  beforeEach(() => {
    loadFixtures(FIXTURE);
    // eslint-disable-next-line no-new
    new UserInternalRegexHandler();
    $userExternal = $('#user_external');
    $userEmail = $('#user_email');
    $warningMessage = $('#warning_external_automatically_set');
    if (!$userExternal.prop('checked')) $userExternal.prop('checked', 'checked');
  });

  describe('Behaviour of userExternal checkbox when', () => {
    it('matches email as internal', (done) => {
      expect($warningMessage.hasClass('hidden')).toBeTruthy();

      $userEmail.val('test@').trigger('input');

      expect($userExternal.prop('checked')).toBeFalsy();
      expect($warningMessage.hasClass('hidden')).toBeFalsy();
      done();
    });

    it('matches email as external', (done) => {
      expect($warningMessage.hasClass('hidden')).toBeTruthy();

      $userEmail.val('test.ext@').trigger('input');

      expect($userExternal.prop('checked')).toBeTruthy();
      expect($warningMessage.hasClass('hidden')).toBeTruthy();
      done();
    });
  });
});
