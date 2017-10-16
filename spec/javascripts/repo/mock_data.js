import RepoHelper from '~/repo/helpers/repo_helper';

// eslint-disable-next-line import/prefer-default-export
export const file = () => RepoHelper.serializeRepoEntity('blob', {
  icon: 'icon',
  url: 'url',
  name: 'name',
  last_commit: {
    id: '123',
    message: 'test',
    committed_date: '',
  },
});
