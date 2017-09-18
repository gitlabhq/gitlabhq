export const imageReplacedData = {
  added: {
    path: `${gl.TEST_HOST}/added.png`,
    alt: 'added',
    size: '100 KB',
  },
  deleted: {
    path: `${gl.TEST_HOST}/deleted.png`,
    alt: 'deleted',
    size: '50 KB',
  },
};

export const imageFrameData = {
  src: `${gl.TEST_HOST}/gitlab.png`,
  alt: 'gitlab-image',
  className: 'class-name',
};

export const loadEvent = {
  target: {
    naturalWidth: 100,
    naturalHeight: 200,
  },
};

export function ImageFile() {}

ImageFile.prototype.views = {
  swipe: () => {},
  'onion-skin': () => {},
};
