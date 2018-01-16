import queryData from '~/boards/utils/query_data';

describe('queryData', () => {
  it('parses path for label with trailing +', () => {
    const path = 'label_name[]=label%2B';
    expect(
      queryData(path, {}),
    ).toEqual({
      label_name: ['label+'],
    });
  });

  it('parses path for milestone with trailing +', () => {
    const path = 'milestone_title=A%2B';
    expect(
      queryData(path, {}),
    ).toEqual({
      milestone_title: 'A+',
    });
  });
});
