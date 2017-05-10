import { borderlessStatusIconEntityMap, statusIconEntityMap } from '~/vue_shared/ci_status_icons';

describe('CI status icons', () => {
  const statuses = [
    'icon_status_canceled',
    'icon_status_created',
    'icon_status_failed',
    'icon_status_manual',
    'icon_status_pending',
    'icon_status_running',
    'icon_status_skipped',
    'icon_status_success',
    'icon_status_warning',
  ];

  it('should have a dictionary for borderless icons', () => {
    statuses.forEach((status) => {
      expect(borderlessStatusIconEntityMap[status]).toBeDefined();
    });
  });

  it('should have a dictionary for icons', () => {
    statuses.forEach((status) => {
      expect(statusIconEntityMap[status]).toBeDefined();
    });
  });
});
