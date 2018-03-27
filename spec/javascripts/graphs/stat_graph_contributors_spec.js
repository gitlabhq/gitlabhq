import ContributorsStatGraph from '~/pages/projects/graphs/show/stat_graph_contributors';
import { ContributorsGraph } from '~/pages/projects/graphs/show/stat_graph_contributors_graph';

import { setLanguage } from '../helpers/locale_helper';

describe('ContributorsStatGraph', () => {
  describe('change_date_header', () => {
    beforeAll(() => {
      setLanguage('de');
    });

    afterAll(() => {
      setLanguage(null);
    });

    it('uses the locale to display date ranges', () => {
      ContributorsGraph.init_x_domain([{ date: '2013-01-31' }, { date: '2012-01-31' }]);
      setFixtures('<div id="date_header"></div>');
      const graph = new ContributorsStatGraph();

      graph.change_date_header();

      expect(document.getElementById('date_header').innerText).toBe('31. Januar 2012 – 31. Januar 2013');
    });
  });
});
