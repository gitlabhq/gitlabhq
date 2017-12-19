import ApproversSelect from 'ee/approvers_select';
import ClassSpecHelper from './helpers/class_spec_helper';

describe('ApproversSelect', () => {
  describe('saveApprovers', () => {
    let complete;
    const $input = jasmine.createSpyObj('$input', ['val']);

    beforeEach(() => {
      spyOn(window, '$').and.returnValue($input);
      spyOn(window.$, 'ajax').and.callFake((options) => {
        complete = options.complete;
      });

      $input.val.and.returnValue('newValue');

      ApproversSelect.saveApprovers('fieldName');
    });

    ClassSpecHelper.itShouldBeAStaticMethod(ApproversSelect, 'saveApprovers');

    describe('when request completes', () => {
      it('should empty the $input value', () => {
        $input.val.calls.reset();

        complete();

        expect($input.val).toHaveBeenCalledWith('');
      });
    });
  });
});
