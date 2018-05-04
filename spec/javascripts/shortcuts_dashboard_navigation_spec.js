import findAndFollowLink from '~/shortcuts_dashboard_navigation';

describe('findAndFollowLink', () => {
  it('visits a link when the selector exists', () => {
    const href = '/some/path';
    const visitUrl = spyOnDependency(findAndFollowLink, 'visitUrl');

    setFixtures(`<a class="my-shortcut" href="${href}">link</a>`);

    findAndFollowLink('.my-shortcut');

    expect(visitUrl).toHaveBeenCalledWith(href);
  });

  it('does not throw an exception when the selector does not exist', () => {
    const visitUrl = spyOnDependency(findAndFollowLink, 'visitUrl');

    // this should not throw an exception
    findAndFollowLink('.this-selector-does-not-exist');

    expect(visitUrl).not.toHaveBeenCalled();
  });
});
