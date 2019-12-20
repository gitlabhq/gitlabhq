import _ from 'underscore';
import { DUMMY_IMAGE_URL, TEST_HOST } from 'spec/test_constants';
import { PROJECT_BADGE } from '~/badges/constants';

export const createDummyBadge = () => {
  const id = _.uniqueId();
  return {
    id,
    name: 'TestBadge',
    imageUrl: `${TEST_HOST}/badges/${id}/image/url`,
    isDeleting: false,
    linkUrl: `${TEST_HOST}/badges/${id}/link/url`,
    kind: PROJECT_BADGE,
    renderedImageUrl: `${DUMMY_IMAGE_URL}?id=${id}`,
    renderedLinkUrl: `${TEST_HOST}/badges/${id}/rendered/link/url`,
  };
};

export const createDummyBadgeResponse = () => ({
  name: 'TestBadge',
  image_url: `${TEST_HOST}/badge/image/url`,
  link_url: `${TEST_HOST}/badge/link/url`,
  kind: PROJECT_BADGE,
  rendered_image_url: DUMMY_IMAGE_URL,
  rendered_link_url: `${TEST_HOST}/rendered/badge/link/url`,
});
