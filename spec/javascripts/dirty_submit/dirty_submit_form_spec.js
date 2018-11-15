import DirtySubmitForm from '~/dirty_submit/dirty_submit_form';
import { setInput, createForm } from './helper';

function expectToToggleDisableOnDirtyUpdate(submit, input) {
  const originalValue = input.value;

  expect(submit.disabled).toBe(true);

  return setInput(input, `${originalValue} changes`)
    .then(() => expect(submit.disabled).toBe(false))
    .then(() => setInput(input, originalValue))
    .then(() => expect(submit.disabled).toBe(true));
}

describe('DirtySubmitForm', () => {
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
});
