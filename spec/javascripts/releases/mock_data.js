export const pageInfoHeadersWithoutPagination = {
  'X-NEXT-PAGE': '',
  'X-PAGE': '1',
  'X-PER-PAGE': '20',
  'X-PREV-PAGE': '',
  'X-TOTAL': '19',
  'X-TOTAL-PAGES': '1',
};

export const pageInfoHeadersWithPagination = {
  'X-NEXT-PAGE': '2',
  'X-PAGE': '1',
  'X-PER-PAGE': '20',
  'X-PREV-PAGE': '',
  'X-TOTAL': '21',
  'X-TOTAL-PAGES': '2',
};

export const release = {
  name: 'Bionic Beaver',
  tag_name: '18.04',
  description: '## changelog\n\n* line 1\n* line2',
  description_html: '<div><h2>changelog</h2><ul><li>line1</li<li>line 2</li></ul></div>',
  author_name: 'Release bot',
  author_email: 'release-bot@example.com',
  created_at: '2012-05-28T05:00:00-07:00',
  commit: {
    id: '2695effb5807a22ff3d138d593fd856244e155e7',
    short_id: '2695effb',
    title: 'Initial commit',
    created_at: '2017-07-26T11:08:53.000+02:00',
    parent_ids: ['2a4b78934375d7f53875269ffd4f45fd83a84ebe'],
    message: 'Initial commit',
    author: {
      avatar_url: 'uploads/-/system/user/avatar/johndoe/avatar.png',
      id: 482476,
      name: 'John Doe',
      path: '/johndoe',
      state: 'active',
      status_tooltip_html: null,
      username: 'johndoe',
      web_url: 'https://gitlab.com/johndoe',
    },
    authored_date: '2012-05-28T04:42:42-07:00',
    committer_name: 'Jack Smith',
    committer_email: 'jack@example.com',
    committed_date: '2012-05-28T04:42:42-07:00',
  },
  assets: {
    count: 6,
    sources: [
      {
        format: 'zip',
        url: 'https://gitlab.com/gitlab-org/gitlab-foss/-/archive/v11.3.12/gitlab-ce-v11.3.12.zip',
      },
      {
        format: 'tar.gz',
        url:
          'https://gitlab.com/gitlab-org/gitlab-foss/-/archive/v11.3.12/gitlab-ce-v11.3.12.tar.gz',
      },
      {
        format: 'tar.bz2',
        url:
          'https://gitlab.com/gitlab-org/gitlab-foss/-/archive/v11.3.12/gitlab-ce-v11.3.12.tar.bz2',
      },
      {
        format: 'tar',
        url: 'https://gitlab.com/gitlab-org/gitlab-foss/-/archive/v11.3.12/gitlab-ce-v11.3.12.tar',
      },
    ],
    links: [
      {
        name: 'release-18.04.dmg',
        url: 'https://my-external-hosting.example.com/scrambled-url/',
        external: true,
      },
      {
        name: 'binary-linux-amd64',
        url:
          'https://gitlab.com/gitlab-org/gitlab-foss/-/jobs/artifacts/v11.6.0-rc4/download?job=rspec-mysql+41%2F50',
        external: false,
      },
    ],
  },
};

export const releases = [
  release,
  {
    name: 'JoJos Bizarre Adventure',
    tag_name: '19.00',
    description: '## changelog\n\n* line 1\n* line2',
    description_html: '<div><h2>changelog</h2><ul><li>line1</li<li>line 2</li></ul></div>',
    author_name: 'Release bot',
    author_email: 'release-bot@example.com',
    created_at: '2012-05-28T05:00:00-07:00',
    commit: {
      id: '2695effb5807a22ff3d138d593fd856244e155e7',
      short_id: '2695effb',
      title: 'Initial commit',
      created_at: '2017-07-26T11:08:53.000+02:00',
      parent_ids: ['2a4b78934375d7f53875269ffd4f45fd83a84ebe'],
      message: 'Initial commit',
      author: {
        avatar_url: 'uploads/-/system/user/avatar/johndoe/avatar.png',
        id: 482476,
        name: 'John Doe',
        path: '/johndoe',
        state: 'active',
        status_tooltip_html: null,
        username: 'johndoe',
        web_url: 'https://gitlab.com/johndoe',
      },
      authored_date: '2012-05-28T04:42:42-07:00',
      committer_name: 'Jack Smith',
      committer_email: 'jack@example.com',
      committed_date: '2012-05-28T04:42:42-07:00',
    },
    assets: {
      count: 4,
      sources: [
        {
          format: 'tar.gz',
          url:
            'https://gitlab.com/gitlab-org/gitlab-foss/-/archive/v11.3.12/gitlab-ce-v11.3.12.tar.gz',
        },
        {
          format: 'tar.bz2',
          url:
            'https://gitlab.com/gitlab-org/gitlab-foss/-/archive/v11.3.12/gitlab-ce-v11.3.12.tar.bz2',
        },
        {
          format: 'tar',
          url:
            'https://gitlab.com/gitlab-org/gitlab-foss/-/archive/v11.3.12/gitlab-ce-v11.3.12.tar',
        },
      ],
      links: [
        {
          name: 'binary-linux-amd64',
          url:
            'https://gitlab.com/gitlab-org/gitlab-foss/-/jobs/artifacts/v11.6.0-rc4/download?job=rspec-mysql+41%2F50',
          external: false,
        },
      ],
    },
  },
];
