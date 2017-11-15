export const contentProps = {
  endpoint: '',
  canAdmin: true,
  canUpdate: true,
  canDestroy: true,
  markdownPreviewPath: '',
  markdownDocsPath: '',
  issueLinksEndpoint: '/',
  groupPath: '',
  initialTitleHtml: '',
  initialTitleText: '',
  startDate: '2017-01-01',
  endDate: '2017-10-10',
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
