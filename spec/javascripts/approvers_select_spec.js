import ApproversSelect from 'ee/approvers_select';

describe('ApproversSelect', () => {
  describe('saveApproversComplete', () => {
    let $input;
    let $approverSelect;
    let $loadWrapper;

    beforeEach(() => {
      $input = {
        val: jasmine.createSpy(),
      };

      $approverSelect = {
        select2: jasmine.createSpy(),
      };

      $loadWrapper = {
        addClass: jasmine.createSpy(),
      };

      ApproversSelect.saveApproversComplete($input, $approverSelect, $loadWrapper);
    });

    it('should empty the $input value', () => {
      expect($input.val).toHaveBeenCalledWith('');
    });

    it('should empty the select2 value', () => {
      expect($approverSelect.select2).toHaveBeenCalledWith('val', '');
    });

    it('should hide loadWrapper', () => {
      expect($loadWrapper.addClass).toHaveBeenCalledWith('hidden');
    });
  });
});
