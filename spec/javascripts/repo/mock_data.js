import RepoHelper from '~/repo/helpers/repo_helper';

// eslint-disable-next-line import/prefer-default-export
export const file = (name = 'name', id = name) => RepoHelper.serializeRepoEntity('blob', {
  id,
  icon: 'icon',
  url: 'url',
  name,
  last_commit: {
    id: '123',
    message: 'test',
    committed_date: new Date().toISOString(),
  },
});
