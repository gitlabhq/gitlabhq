import initSettingsPanels from '~/settings_panels';

describe('Settings Panels', () => {
  preloadFixtures('projects/ci_cd_settings.html.raw');

  beforeEach(() => {
    loadFixtures('projects/ci_cd_settings.html.raw');
  });

  describe('initSettingsPane', () => {
    afterEach(() => {
      location.hash = '';
    });

    it('should expand linked hash fragment panel', () => {
      location.hash = '#autodevops-settings';

      const pipelineSettingsPanel = document.querySelector('#autodevops-settings');
      // Our test environment automatically expands everything so we need to clear that out first
      pipelineSettingsPanel.classList.remove('expanded');

      expect(pipelineSettingsPanel.classList.contains('expanded')).toBe(false);

      initSettingsPanels();

      expect(pipelineSettingsPanel.classList.contains('expanded')).toBe(true);
    });
  });
});
