import getSafeBranchName from '~/repo/helpers/get_safe_branch_name_helper';

describe('getSafeBranchName', () => {
  it('does not replace repeated dashes with single dashes', () => {
    const branch = 'some--branch--name';
    expect(getSafeBranchName(branch)).toBe(branch);
  });

  it('removes non-alphanumeric characters', () => {
    const branch = '$some#-branch!';
    expect(getSafeBranchName(branch)).toBe('some-branch');
  });
});
