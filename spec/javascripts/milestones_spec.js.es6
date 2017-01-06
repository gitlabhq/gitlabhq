/*= require jquery */
(() => {
  describe('MilestonePanel', () => {
    const issuesCount = '.pull-right';
    const fixtureTemplate = 'issuables.html';

    function setIssuesCount(newCount) {
      $(issuesCount).text(newCount);
    }

    fixture.preload(fixtureTemplate);
    beforeEach(() => {
      fixture.load(fixtureTemplate);
    });

    it('should add delimiter to the issues count', () => {
      setIssuesCount(1000);
      expect($(issuesCount).text()).toEqual('1,000');
    });
  });
})();
