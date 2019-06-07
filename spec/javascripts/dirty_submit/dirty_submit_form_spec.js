import _ from 'underscore';
import DirtySubmitForm from '~/dirty_submit/dirty_submit_form';
import { getInputValue, setInputValue, createForm } from './helper';

function expectToToggleDisableOnDirtyUpdate(submit, input) {
  const originalValue = getInputValue(input);

  expect(submit.disabled).toBe(true);

  return setInputValue(input, `${originalValue} changes`)
    .then(() => expect(submit.disabled).toBe(false))
    .then(() => setInputValue(input, originalValue))
    .then(() => expect(submit.disabled).toBe(true));
}

describe('DirtySubmitForm', () => {
  const originalThrottleDuration = DirtySubmitForm.THROTTLE_DURATION;

  describe('submit button tests', () => {
    beforeEach(() => {
      DirtySubmitForm.THROTTLE_DURATION = 0;
    });

    afterEach(() => {
      DirtySubmitForm.THROTTLE_DURATION = originalThrottleDuration;
    });

    it('disables submit until there are changes', done => {
      const { form, input, submit } = createForm();

      new DirtySubmitForm(form); // eslint-disable-line no-new

      return expectToToggleDisableOnDirtyUpdate(submit, input)
        .then(done)
        .catch(done.fail);
    });

    it('disables submit until there are changes when initializing with a falsy value', done => {
      const { form, input, submit } = createForm();
      input.value = '';

      new DirtySubmitForm(form); // eslint-disable-line no-new

      return expectToToggleDisableOnDirtyUpdate(submit, input)
        .then(done)
        .catch(done.fail);
    });

    it('disables submit until there are changes for radio inputs', done => {
      const { form, input, submit } = createForm('radio');

      new DirtySubmitForm(form); // eslint-disable-line no-new

      return expectToToggleDisableOnDirtyUpdate(submit, input)
        .then(done)
        .catch(done.fail);
    });

    it('disables submit until there are changes for checkbox inputs', done => {
      const { form, input, submit } = createForm('checkbox');

      new DirtySubmitForm(form); // eslint-disable-line no-new

      return expectToToggleDisableOnDirtyUpdate(submit, input)
        .then(done)
        .catch(done.fail);
    });
  });

  describe('throttling tests', () => {
    beforeEach(() => {
      jasmine.clock().install();
      DirtySubmitForm.THROTTLE_DURATION = 100;
    });

    afterEach(() => {
      jasmine.clock().uninstall();
      DirtySubmitForm.THROTTLE_DURATION = originalThrottleDuration;
    });

    it('throttles updates when rapid changes are made to a single form element', () => {
      const { form, input } = createForm();
      const updateDirtyInputSpy = spyOn(new DirtySubmitForm(form), 'updateDirtyInput');

      _.range(10).forEach(i => {
        setInputValue(input, `change ${i}`, false);
      });

      jasmine.clock().tick(101);

      expect(updateDirtyInputSpy).toHaveBeenCalledTimes(2);
    });

    it('does not throttle updates when rapid changes are made to different form elements', () => {
      const form = document.createElement('form');
      const range = _.range(10);
      range.forEach(i => {
        form.innerHTML += `<input type="text" name="input-${i}" class="js-input-${i}"/>`;
      });

      const updateDirtyInputSpy = spyOn(new DirtySubmitForm(form), 'updateDirtyInput');

      range.forEach(i => {
        const input = form.querySelector(`.js-input-${i}`);
        setInputValue(input, `change`, false);
      });

      jasmine.clock().tick(101);

      expect(updateDirtyInputSpy).toHaveBeenCalledTimes(range.length);
    });
  });
});
