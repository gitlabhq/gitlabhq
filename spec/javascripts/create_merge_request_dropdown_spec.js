import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';
import CreateMergeRequestDropdown from '~/create_merge_request_dropdown';
import { TEST_HOST } from 'spec/test_constants';

describe('CreateMergeRequestDropdown', () => {
  let axiosMock;
  let dropdown;

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);

    setFixtures(`
      <div id="dummy-wrapper-element">
        <div class="available"></div>
        <div class="unavailable">
          <div class="fa"></div>
          <div class="text"></div>
        </div>
        <div class="js-ref"></div>
        <div class="js-create-merge-request"></div>
        <div class="js-create-target"></div>
        <div class="js-dropdown-toggle"></div>
      </div>
    `);

    const dummyElement = document.getElementById('dummy-wrapper-element');
    dropdown = new CreateMergeRequestDropdown(dummyElement);
    dropdown.refsPath = `${TEST_HOST}/dummy/refs?search=`;
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('getRef', () => {
    it('escapes branch names correctly', done => {
      const endpoint = `${dropdown.refsPath}contains%23hash`;
      spyOn(axios, 'get').and.callThrough();
      axiosMock.onGet(endpoint).replyOnce({});

      dropdown
        .getRef('contains#hash')
        .then(() => {
          expect(axios.get).toHaveBeenCalledWith(endpoint);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('updateCreatePaths', () => {
    it('escapes branch names correctly', () => {
      dropdown.createBranchPath = `${TEST_HOST}/branches?branch_name=some-branch&issue=42`;
      dropdown.createMrPath = `${TEST_HOST}/create_merge_request?branch_name=some-branch&ref=master`;

      dropdown.updateCreatePaths('branch', 'contains#hash');

      expect(dropdown.createBranchPath).toBe(
        `${TEST_HOST}/branches?branch_name=contains%23hash&issue=42`,
      );
      expect(dropdown.createMrPath).toBe(
        `${TEST_HOST}/create_merge_request?branch_name=contains%23hash&ref=master`,
      );
    });
  });
});
