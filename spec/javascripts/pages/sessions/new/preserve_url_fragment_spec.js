import $ from 'jquery';
import preserveUrlFragment from '~/pages/sessions/new/preserve_url_fragment';

describe('preserve_url_fragment', () => {
  preloadFixtures('static/signin_forms_and_buttons.html.raw');

  beforeEach(() => {
    loadFixtures('static/signin_forms_and_buttons.html.raw');
  });

  it('adds the url fragment to all login and sign up form actions', () => {
    preserveUrlFragment('#L65');

    expect($('#new_ldap_user').attr('action')).toBe('/users/auth/ldapmain/callback#L65');
    expect($('#new_user').attr('action')).toBe('/users/sign_in#L65');
    expect($('#new_new_user').attr('action')).toBe('/users#L65');
  });

  it('adds the "redirect_fragment" query parameter to all OAuth and SAML login buttons', () => {
    preserveUrlFragment('#L65');

    expect($('.omniauth-container #oauth-login-auth0').attr('href')).toBe('/users/auth/auth0?redirect_fragment=L65');
    expect($('.omniauth-container #oauth-login-facebook').attr('href')).toBe('/users/auth/facebook?remember_me=1&redirect_fragment=L65');
    expect($('.omniauth-container #oauth-login-saml').attr('href')).toBe('/users/auth/saml?redirect_fragment=L65');
  });
});
