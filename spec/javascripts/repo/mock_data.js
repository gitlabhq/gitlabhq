import RepoHelper from '~/repo/helpers/repo_helper';

export const file = () => RepoHelper.serializeBlob({
  icon: 'icon',
  url: 'url',
  name: 'name',
  last_commit: {
    id: '123',
    message: 'test',
    committed_date: '',
  },
});
