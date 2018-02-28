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
    beforeEach(() => {
      const element = document.createElement('a');
      element.classList.add('incoming-email-token-reset');
      element.setAttribute('href', 'foo');
      document.body.appendChild(element);

      const input = document.createElement('input');
      input.setAttribute('id', 'issue_email');
      document.body.appendChild(input);

      Issuable = new IssuableIndex('issue_');
    });

    it('should send request to reset email token', () => {
      spyOn(jQuery, 'ajax').and.callThrough();
      document.querySelector('.incoming-email-token-reset').click();

      expect(jQuery.ajax).toHaveBeenCalled();
      expect(jQuery.ajax.calls.argsFor(0)[0].url).toEqual('foo');
    });
  });
});

