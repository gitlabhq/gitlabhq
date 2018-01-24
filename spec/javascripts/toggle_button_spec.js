import Vue from 'vue';
import ToggleButton from '~/toggle_button';
import getSetTimeoutPromise from './helpers/set_timeout_promise_helper';

function generateMarkup(isChecked = true) {
  return `
    <input type="hidden" class="js-project-feature-toggle" name="some-feature" value="${isChecked}" />
  `;
}

function setupFixture(isChecked, clickCallback) {
  const wrapper = document.createElement('div');
  wrapper.innerHTML = generateMarkup(isChecked);

  const toggleButton = new ToggleButton(wrapper.querySelector('.js-project-feature-toggle'), clickCallback);
  toggleButton.init();

  return wrapper;
}

describe('ToggleButtons', () => {
  describe('when input value is true', () => {
    it('should initialize as checked', () => {
      const wrapper = setupFixture(true);

      expect(wrapper.querySelector('button').classList.contains('is-checked')).toEqual(true);
      expect(wrapper.querySelector('input').value).toEqual('true');
    });

    it('should toggle to unchecked when clicked', (done) => {
      const wrapper = setupFixture(true);
      const toggleButton = wrapper.querySelector('button');

      toggleButton.click();

      getSetTimeoutPromise()
        .then(() => {
          expect(toggleButton.classList.contains('is-checked')).toEqual(false);
          expect(wrapper.querySelector('input').value).toEqual('false');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('when input value is false', () => {
    it('should initialize as unchecked', () => {
      const wrapper = setupFixture(false);

      expect(wrapper.querySelector('button').classList.contains('is-checked')).toEqual(false);
      expect(wrapper.querySelector('input').value).toEqual('false');
    });

    it('should toggle to checked when clicked', (done) => {
      const wrapper = setupFixture(false);
      const toggleButton = wrapper.querySelector('button');

      toggleButton.click();

      getSetTimeoutPromise()
        .then(() => {
          expect(toggleButton.classList.contains('is-checked')).toEqual(true);
          expect(wrapper.querySelector('input').value).toEqual('true');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('clickCallback option', () => {
    it('should show loading indicator while waiting', (done) => {
      let wrapper;
      const isChecked = true;
      const clickCallback = (newValue) => {
        const toggleButton = wrapper.querySelector('button');
        const input = wrapper.querySelector('input');

        expect(newValue).toEqual(false);

        const firstExpectationsPromise = Vue.nextTick()
          .then(() => {
            // Check for the loading state
            expect(toggleButton.classList.contains('is-checked')).toEqual(false);
            expect(toggleButton.classList.contains('is-loading')).toEqual(true);
            expect(toggleButton.disabled).toEqual(true);
            expect(input.value).toEqual('false');
          });

        // After the callback finishes, check that the loading state is gone
        firstExpectationsPromise
          .then(Vue.nextTick)
          .then(() => {
            expect(toggleButton.classList.contains('is-checked')).toEqual(false);
            expect(toggleButton.classList.contains('is-loading')).toEqual(false);
            expect(toggleButton.disabled).toEqual(false);
            expect(input.value).toEqual('false');
          })
          .then(done)
          .catch(done.fail);

        return firstExpectationsPromise;
      };

      wrapper = setupFixture(isChecked, clickCallback);
      const toggleButton = wrapper.querySelector('button');

      toggleButton.click();
    });
  });
});
