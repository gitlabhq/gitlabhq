import DirtySubmitForm from '~/dirty_submit/dirty_submit_form';
import setTimeoutPromiseHelper from '../helpers/set_timeout_promise_helper';

export function setInput(element, value) {
  element.value = value;

  element.dispatchEvent(
    new Event('input', {
      bubbles: true,
      cancelable: true,
    }),
  );

  return setTimeoutPromiseHelper(DirtySubmitForm.THROTTLE_DURATION);
}

export function createForm() {
  const form = document.createElement('form');
  form.innerHTML = `
    <input type="text" value="original" class="js-input" name="input" />
    <button type="submit" class="js-dirty-submit"></button>
  `;
  const input = form.querySelector('.js-input');
  const submit = form.querySelector('.js-dirty-submit');

  return {
    form,
    input,
    submit,
  };
}
