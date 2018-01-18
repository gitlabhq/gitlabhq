import queryData from '~/boards/utils/query_data';

describe('queryData', () => {
  it('parses path for label with trailing +', () => {
    expect(
      queryData('label_name[]=label%2B', {}),
    ).toEqual({
      label_name: ['label+'],
    });
  });

  it('parses path for milestone with trailing +', () => {
    expect(
      queryData('milestone_title=A%2B', {}),
    ).toEqual({
      milestone_title: 'A+',
    });
  });

  it('parses path for search terms with spaces', () => {
    expect(
      queryData('search=two+words', {}),
    ).toEqual({
      search: 'two words',
    });
  });
});
