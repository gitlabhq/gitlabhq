import { ImporterStatus } from '~/importer_status';
import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';

describe('Importer Status', () => {
  describe('addToImport', () => {
    let instance;
    let mock;
    const importUrl = '/import_url';

    beforeEach(() => {
      setFixtures(`
        <tr id="repo_123">
          <td class="import-target"></td>
          <td class="import-actions job-status">
            <button name="button" type="submit" class="btn btn-import js-add-to-import">
            </button>
          </td>
        </tr>
      `);
      spyOn(ImporterStatus.prototype, 'initStatusPage').and.callFake(() => {});
      spyOn(ImporterStatus.prototype, 'setAutoUpdate').and.callFake(() => {});
      instance = new ImporterStatus('', importUrl);
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    it('sets table row to active after post request', (done) => {
      mock.onPost(importUrl).reply(200, {
        id: 1,
        full_path: '/full_path',
      });

      instance.addToImport({
        currentTarget: document.querySelector('.js-add-to-import'),
      })
      .then(() => {
        expect(document.querySelector('tr').classList.contains('active')).toEqual(true);
        done();
      })
      .catch(done.fail);
    });
  });
});
