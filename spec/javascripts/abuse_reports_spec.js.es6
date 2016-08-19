/*= require abuse_reports */

/*= require jquery */

((global) => {
  const FIXTURE = 'abuse_reports.html';
  const MAX_MESSAGE_LENGTH = 500;

  function assertMaxLength($message) {
    expect($message.text().length).toEqual(MAX_MESSAGE_LENGTH);
  }

  describe('Abuse Reports', function() {
    fixture.preload(FIXTURE);

    beforeEach(function() {
      fixture.load(FIXTURE);
      new global.AbuseReports();
    });

    it('should truncate long messages', function() {
      const $longMessage = $('#long');
      expect($longMessage.data('original-message')).toEqual(jasmine.anything());
      assertMaxLength($longMessage);
    });

    it('should not truncate short messages', function() {
      const $shortMessage = $('#short');
      expect($shortMessage.data('original-message')).not.toEqual(jasmine.anything());
    });

    it('should allow clicking a truncated message to expand and collapse the full message', function() {
      const $longMessage = $('#long');
      $longMessage.click();
      expect($longMessage.data('original-message').length).toEqual($longMessage.text().length);
      $longMessage.click();
      assertMaxLength($longMessage);
    });
  });

})(window.gl);
