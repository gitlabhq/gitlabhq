import $ from 'jquery';
import OAuthRememberMe from '~/pages/sessions/new/oauth_remember_me';

describe('OAuthRememberMe', () => {
  preloadFixtures('static/oauth_remember_me.html.raw');

  beforeEach(() => {
    loadFixtures('static/oauth_remember_me.html.raw');

    new OAuthRememberMe({ container: $('#oauth-container') }).bindEvents();
  });

  it('adds the "remember_me" query parameter to all OAuth login buttons', () => {
    $('#oauth-container #remember_me').click();

    expect($('#oauth-container .oauth-login.twitter').attr('href')).toBe('http://example.com/?remember_me=1');
    expect($('#oauth-container .oauth-login.github').attr('href')).toBe('http://example.com/?remember_me=1');
  });

  it('removes the "remember_me" query parameter from all OAuth login buttons', () => {
    $('#oauth-container #remember_me').click();
    $('#oauth-container #remember_me').click();

    expect($('#oauth-container .oauth-login.twitter').attr('href')).toBe('http://example.com/');
    expect($('#oauth-container .oauth-login.github').attr('href')).toBe('http://example.com/');
  });
});
