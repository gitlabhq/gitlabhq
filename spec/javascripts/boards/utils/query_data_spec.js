import queryData from '~/boards/utils/query_data';

describe('queryData', () => {
  describe('filters milestones', () => {
    it('by No Milestone', () => {
      expect(
        queryData('milestone_title=No+Milestone', {}),
      ).toEqual({
        milestone_title: 'No Milestone',
      });
    });

    it('by Upcoming Milestone', () => {
      expect(
        queryData('milestone_title=%23upcoming', {}),
      ).toEqual({
        milestone_title: '#upcoming',
      });
    });

    it('by Started Milestone', () => {
      expect(
        queryData('milestone_title=%23started', {}),
      ).toEqual({
        milestone_title: '#started',
      });
    });

    it('with + in the name', () => {
      expect(
        queryData('milestone_title=A%2B', {}),
      ).toEqual({
        milestone_title: 'A+',
      });
    });

    it('with space in the name', () => {
      expect(
        queryData('milestone_title=Milestone%20with%20spaces', {}),
      ).toEqual({
        milestone_title: 'Milestone with spaces',
      });
    });
  });

  describe('filters labels', () => {
    it('by No Label', () => {
      expect(
        queryData('label_name[]=No+Label', {}),
      ).toEqual({
        label_name: ['No Label'],
      });
    });

    it('with + in label name', () => {
      expect(
        queryData('label_name[]=label%2B', {}),
      ).toEqual({
        label_name: ['label+'],
      });
    });
  });

  describe('text search', () => {
    it('with spaces', () => {
      expect(
        queryData('search=two+words', {}),
      ).toEqual({
        search: 'two words',
      });
    });
  });
});
