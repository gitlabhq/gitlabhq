import DirtySubmitForm from '~/dirty_submit/dirty_submit_form';
import { setInput, createForm } from './helper';

describe('DirtySubmitForm', () => {
  it('disables submit until there are changes', done => {
    const { form, input, submit } = createForm();
    const originalValue = input.value;

    new DirtySubmitForm(form); // eslint-disable-line no-new

    expect(submit.disabled).toBe(true);

    return setInput(input, `${originalValue} changes`)
      .then(() => {
        expect(submit.disabled).toBe(false);
      })
      .then(() => setInput(input, originalValue))
      .then(() => {
        expect(submit.disabled).toBe(true);
      })
      .then(done)
      .catch(done.fail);
  });
});
