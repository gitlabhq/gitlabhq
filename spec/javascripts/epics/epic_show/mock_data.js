export const contentProps = {
  endpoint: '',
  canUpdate: true,
  canDestroy: false,
  markdownPreviewPath: '',
  markdownDocsPath: '',
  groupPath: '',
  initialTitleHtml: '',
  initialTitleText: '',
};

export const headerProps = {
  author: {
    url: `${gl.TEST_HOST}/url`,
    src: `${gl.TEST_HOST}/image`,
    username: '@root',
    name: 'Administrator',
  },
  created: (new Date()).toISOString(),
};

export const props = Object.assign({}, contentProps, headerProps);
