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
  DirtySubmitForm.THROTTLE_DURATION = 0;

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
