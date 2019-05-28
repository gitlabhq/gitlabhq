import $ from 'jquery';
import initSettingsPanels from '~/settings_panels';

describe('Settings Panels', () => {
  preloadFixtures('groups/edit.html');

  beforeEach(() => {
    loadFixtures('groups/edit.html');
  });

  describe('initSettingsPane', () => {
    afterEach(() => {
      window.location.hash = '';
    });

    it('should expand linked hash fragment panel', () => {
      window.location.hash = '#js-general-settings';

      const panel = document.querySelector('#js-general-settings');
      // Our test environment automatically expands everything so we need to clear that out first
      panel.classList.remove('expanded');

      expect(panel.classList.contains('expanded')).toBe(false);

      initSettingsPanels();

      expect(panel.classList.contains('expanded')).toBe(true);
    });
  });

  it('does not change the text content of triggers', () => {
    const panel = document.querySelector('#js-general-settings');
    const trigger = panel.querySelector('.js-settings-toggle-trigger-only');
    const originalText = trigger.textContent;

    initSettingsPanels();

    expect(panel.classList.contains('expanded')).toBe(true);

    $(trigger).click();

    expect(panel.classList.contains('expanded')).toBe(false);
    expect(trigger.textContent).toEqual(originalText);
  });
});
