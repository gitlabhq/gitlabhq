import { FIXTURES_PATH } from 'spec/test_constants';
import BalsamiqViewer from '~/blob/balsamiq/balsamiq_viewer';

const bmprPath = `${FIXTURES_PATH}/blob/balsamiq/test.bmpr`;

describe('Balsamiq integration spec', () => {
  let container;
  let endpoint;
  let balsamiqViewer;

  preloadFixtures('static/balsamiq_viewer.html');

  beforeEach(() => {
    loadFixtures('static/balsamiq_viewer.html');

    container = document.getElementById('js-balsamiq-viewer');
    balsamiqViewer = new BalsamiqViewer(container);
  });

  describe('successful response', () => {
    beforeEach(done => {
      endpoint = bmprPath;

      balsamiqViewer
        .loadFile(endpoint)
        .then(done)
        .catch(done.fail);
    });

    it('does not show loading icon', () => {
      expect(document.querySelector('.loading')).toBeNull();
    });

    it('renders the balsamiq previews', () => {
      expect(document.querySelectorAll('.previews .preview').length).not.toEqual(0);
    });
  });

  describe('error getting file', () => {
    beforeEach(done => {
      endpoint = 'invalid/path/to/file.bmpr';

      balsamiqViewer
        .loadFile(endpoint)
        .then(done.fail, null)
        .catch(done);
    });

    it('does not show loading icon', () => {
      expect(document.querySelector('.loading')).toBeNull();
    });

    it('does not render the balsamiq previews', () => {
      expect(document.querySelectorAll('.previews .preview').length).toEqual(0);
    });
  });
});
