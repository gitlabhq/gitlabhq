import $ from 'jquery';
import MockAdaptor from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import IssuableIndex from '~/issuable_index';

describe('Issuable', () => {
  let Issuable;
  describe('initBulkUpdate', () => {
    it('should not set bulkUpdateSidebar', () => {
      Issuable = new IssuableIndex('issue_');
      expect(Issuable.bulkUpdateSidebar).not.toBeDefined();
    });

    it('should set bulkUpdateSidebar', () => {
      const element = document.createElement('div');
      element.classList.add('issues-bulk-update');
      document.body.appendChild(element);

      Issuable = new IssuableIndex('issue_');
      expect(Issuable.bulkUpdateSidebar).toBeDefined();
    });
  });

  describe('resetIncomingEmailToken', () => {
    let mock;

    beforeEach(() => {
      const element = document.createElement('a');
      element.classList.add('incoming-email-token-reset');
      element.setAttribute('href', 'foo');
      document.body.appendChild(element);

      const input = document.createElement('input');
      input.setAttribute('id', 'issuable_email');
      document.body.appendChild(input);

      Issuable = new IssuableIndex('issue_');

      mock = new MockAdaptor(axios);

      mock.onPut('foo').reply(200, {
        new_address: 'testing123',
      });
    });

    afterEach(() => {
      mock.restore();
    });

    it('should send request to reset email token', (done) => {
      spyOn(axios, 'put').and.callThrough();
      document.querySelector('.incoming-email-token-reset').click();

      setTimeout(() => {
        expect(axios.put).toHaveBeenCalledWith('foo');
        expect($('#issuable_email').val()).toBe('testing123');

        done();
      });
    });
  });
});

