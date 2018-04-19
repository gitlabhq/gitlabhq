import $ from 'jquery';
import '~/behaviors/autosize';

function load() {
  $(document).trigger('load');
}

describe('Autosize behavior', () => {
  beforeEach(() => {
    setFixtures('<textarea class="js-autosize" style="resize: vertical"></textarea>');
  });

  it('does not overwrite the resize property', () => {
    load();
    expect($('textarea')).toHaveCss({
      resize: 'vertical',
    });
  });
});
