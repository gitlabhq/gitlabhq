import { ImporterStatus } from '~/importer_status';
import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';

describe('Importer Status', () => {
  let instance;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('addToImport', () => {
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
      instance = new ImporterStatus({
        jobsUrl: '',
        importUrl,
      });
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

  describe('autoUpdate', () => {
    const jobsUrl = '/jobs_url';

    beforeEach(() => {
      const div = document.createElement('div');
      div.innerHTML = `
        <div id="project_1">
          <div class="job-status">
          </div>
        </div>
      `;

      document.body.appendChild(div);

      spyOn(ImporterStatus.prototype, 'initStatusPage').and.callFake(() => {});
      spyOn(ImporterStatus.prototype, 'setAutoUpdate').and.callFake(() => {});
      instance = new ImporterStatus({
        jobsUrl,
      });
    });

    function setupMock(importStatus) {
      mock.onGet(jobsUrl).reply(200, [{
        id: 1,
        import_status: importStatus,
      }]);
    }

    function expectJobStatus(done, status) {
      instance.autoUpdate()
        .then(() => {
          expect(document.querySelector('#project_1').innerText.trim()).toEqual(status);
          done();
        })
        .catch(done.fail);
    }

    it('sets the job status to done', (done) => {
      setupMock('finished');
      expectJobStatus(done, 'Done');
    });

    it('sets the job status to scheduled', (done) => {
      setupMock('scheduled');
      expectJobStatus(done, 'Scheduled');
    });

    it('sets the job status to started', (done) => {
      setupMock('started');
      expectJobStatus(done, 'Started');
    });

    it('sets the job status to custom status', (done) => {
      setupMock('custom status');
      expectJobStatus(done, 'custom status');
    });
  });
});
