// eslint-disable-next-line import/prefer-default-export
export const jobLog = [
  {
    offset: 1000,
    content: [{ text: 'Running with gitlab-runner 12.1.0 (de7731dd)' }],
  },
  {
    offset: 1001,
    content: [{ text: ' on docker-auto-scale-com 8a6210b8' }],
  },
  {
    offset: 1002,
    content: [
      {
        text: 'Using Docker executor with image dev.gitlab.org3',
      },
    ],
    sections: ['prepare-executor'],
    section_header: true,
  },
  {
    offset: 1003,
    content: [{ text: 'Starting service postgres:9.6.14 ...', style: 'text-green' }],
    sections: ['prepare-executor'],
  },
];
