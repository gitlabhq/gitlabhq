export const FIXTURES_PATH = `/base/${
  process.env.IS_GITLAB_EE ? 'ee/' : ''
}spec/javascripts/fixtures`;
export const TEST_HOST = 'http://test.host';

export const DUMMY_IMAGE_URL = `${FIXTURES_PATH}/static/images/one_white_pixel.png`;

export const GREEN_BOX_IMAGE_URL = `${FIXTURES_PATH}/static/images/green_box.png`;
export const RED_BOX_IMAGE_URL = `${FIXTURES_PATH}/static/images/red_box.png`;
