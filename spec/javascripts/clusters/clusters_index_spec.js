import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import setClusterTableToggles from '~/clusters/clusters_index';
import { setTimeout } from 'core-js/library/web/timers';

describe('Clusters table', () => {
  preloadFixtures('clusters/index_cluster.html.raw');
  let mock;

  beforeEach(() => {
    loadFixtures('clusters/index_cluster.html.raw');
    mock = new MockAdapter(axios);
    setClusterTableToggles();
  });

  describe('update cluster', () => {
    it('renders loading state while request is made', () => {
      const button = document.querySelector('.js-toggle-cluster-list');

      button.click();

      expect(button.classList).toContain('is-loading');
      expect(button.getAttribute('disabled')).toEqual('true');
    });

    afterEach(() => {
      mock.restore();
    });

    it('shows updated state after sucessfull request', (done) => {
      mock.onPut().reply(200, {}, {});
      const button = document.querySelector('.js-toggle-cluster-list');
      button.click();

      expect(button.classList).toContain('is-loading');

      setTimeout(() => {
        expect(button.classList).not.toContain('is-loading');
        expect(button.classList).not.toContain('is-checked');
        done();
      }, 0);
    });

    it('shows inital state after failed request', (done) => {
      mock.onPut().reply(500, {}, {});
      const button = document.querySelector('.js-toggle-cluster-list');

      button.click();
      expect(button.classList).toContain('is-loading');

      setTimeout(() => {
        expect(button.classList).not.toContain('is-loading');
        expect(button.classList).toContain('is-checked');
        done();
      }, 0);
    });
  });
});
