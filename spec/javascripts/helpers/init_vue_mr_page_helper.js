import MockAdapter from 'axios-mock-adapter';
import initMRPage from '~/mr_notes/index';
import axios from '~/lib/utils/axios_utils';
import { userDataMock, notesDataMock, noteableDataMock } from '../notes/mock_data';
import diffFileMockData from '../diffs/mock_data/diff_file';

export default function initVueMRPage() {
  const mrTestEl = document.createElement('div');
  mrTestEl.className = 'js-merge-request-test';
  document.body.appendChild(mrTestEl);

  const diffsAppEndpoint = '/diffs/app/endpoint';
  const diffsAppProjectPath = 'testproject';
  const mrEl = document.createElement('div');
  mrEl.className = 'merge-request fixture-mr';
  mrEl.setAttribute('data-mr-action', 'diffs');
  mrTestEl.appendChild(mrEl);

  const mrDiscussionsEl = document.createElement('div');
  mrDiscussionsEl.id = 'js-vue-mr-discussions';
  mrDiscussionsEl.setAttribute('data-current-user-data', JSON.stringify(userDataMock));
  mrDiscussionsEl.setAttribute('data-noteable-data', JSON.stringify(noteableDataMock));
  mrDiscussionsEl.setAttribute('data-notes-data', JSON.stringify(notesDataMock));
  mrDiscussionsEl.setAttribute('data-noteable-type', 'merge-request');
  mrTestEl.appendChild(mrDiscussionsEl);

  const discussionCounterEl = document.createElement('div');
  discussionCounterEl.id = 'js-vue-discussion-counter';
  mrTestEl.appendChild(discussionCounterEl);

  const diffsAppEl = document.createElement('div');
  diffsAppEl.id = 'js-diffs-app';
  diffsAppEl.setAttribute('data-endpoint', diffsAppEndpoint);
  diffsAppEl.setAttribute('data-project-path', diffsAppProjectPath);
  diffsAppEl.setAttribute('data-current-user-data', JSON.stringify(userDataMock));
  mrTestEl.appendChild(diffsAppEl);

  const mock = new MockAdapter(axios);
  mock.onGet(diffsAppEndpoint).reply(200, {
    branch_name: 'foo',
    diff_files: [diffFileMockData],
  });

  initMRPage();
  return mock;
}
