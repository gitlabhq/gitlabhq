import getActionIcon from '~/vue_shared/ci_action_icons';
import cancelSVG from 'icons/_icon_action_cancel.svg';
import retrySVG from 'icons/_icon_action_retry.svg';
import playSVG from 'icons/_icon_action_play.svg';

describe('getActionIcon', () => {
  it('should return an empty string', () => {
    expect(getActionIcon()).toEqual('');
  });

  it('should return cancel svg', () => {
    expect(getActionIcon('icon_action_cancel')).toEqual(cancelSVG);
  });

  it('should return retry svg', () => {
    expect(getActionIcon('icon_action_retry')).toEqual(retrySVG);
  });

  it('should return play svg', () => {
    expect(getActionIcon('icon_action_play')).toEqual(playSVG);
  });
});
