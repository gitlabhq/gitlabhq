import findAndFollowLink from '~/shortcuts_dashboard_navigation';
import * as urlUtility from '~/lib/utils/url_utility';

describe('findAndFollowLink', () => {
  it('visits a link when the selector exists', () => {
    const href = '/some/path';
    const locationSpy = spyOn(urlUtility, 'visitUrl');

    setFixtures(`<a class="my-shortcut" href="${href}">link</a>`);

    findAndFollowLink('.my-shortcut');

    expect(locationSpy).toHaveBeenCalledWith(href);
  });

  it('does not throw an exception when the selector does not exist', () => {
    const locationSpy = spyOn(urlUtility, 'visitUrl');

    // this should not throw an exception
    findAndFollowLink('.this-selector-does-not-exist');

    expect(locationSpy).not.toHaveBeenCalled();
  });
});
