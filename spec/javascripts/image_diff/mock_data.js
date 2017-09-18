export const imageReplacedData = {
  added: {
    path: 'https://host.invalid/added.png',
    alt: 'added',
    size: '100 KB',
  },
  deleted: {
    path: 'https://host.invalid/deleted.png',
    alt: 'deleted',
    size: '50 KB',
  },
};

export const imageFrameData = {
  src: 'https://host.invalid/gitlab.png',
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
