import $ from 'jquery';
import setupToggleButtons from '~/toggle_buttons';
import getSetTimeoutPromise from './helpers/set_timeout_promise_helper';

function generateMarkup(isChecked = true) {
  return `
    <button type="button" class="${isChecked ? 'is-checked' : ''} js-project-feature-toggle">
      <input type="hidden" class="js-project-feature-toggle-input" value="${isChecked}" />
    </button>
  `;
}

function setupFixture(isChecked, clickCallback) {
  const wrapper = document.createElement('div');
  wrapper.innerHTML = generateMarkup(isChecked);

  setupToggleButtons(wrapper, clickCallback);

  return wrapper;
}

describe('ToggleButtons', () => {
  describe('when input value is true', () => {
    it('should initialize as checked', () => {
      const wrapper = setupFixture(true);

      expect(wrapper.querySelector('.js-project-feature-toggle').classList.contains('is-checked')).toEqual(true);
      expect(wrapper.querySelector('.js-project-feature-toggle-input').value).toEqual('true');
    });

    it('should toggle to unchecked when clicked', (done) => {
      const wrapper = setupFixture(true);
      const toggleButton = wrapper.querySelector('.js-project-feature-toggle');

      toggleButton.click();

      getSetTimeoutPromise()
        .then(() => {
          expect(toggleButton.classList.contains('is-checked')).toEqual(false);
          expect(wrapper.querySelector('.js-project-feature-toggle-input').value).toEqual('false');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('when input value is false', () => {
    it('should initialize as unchecked', () => {
      const wrapper = setupFixture(false);

      expect(wrapper.querySelector('.js-project-feature-toggle').classList.contains('is-checked')).toEqual(false);
      expect(wrapper.querySelector('.js-project-feature-toggle-input').value).toEqual('false');
    });

    it('should toggle to checked when clicked', (done) => {
      const wrapper = setupFixture(false);
      const toggleButton = wrapper.querySelector('.js-project-feature-toggle');

      toggleButton.click();

      getSetTimeoutPromise()
        .then(() => {
          expect(toggleButton.classList.contains('is-checked')).toEqual(true);
          expect(wrapper.querySelector('.js-project-feature-toggle-input').value).toEqual('true');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  it('should emit `trigger-change` event', (done) => {
    const changeSpy = jasmine.createSpy('changeEventHandler');
    const wrapper = setupFixture(false);
    const toggleButton = wrapper.querySelector('.js-project-feature-toggle');
    const input = wrapper.querySelector('.js-project-feature-toggle-input');

    $(input).on('trigger-change', changeSpy);

    toggleButton.click();

    getSetTimeoutPromise()
      .then(() => {
        expect(changeSpy).toHaveBeenCalled();
      })
      .then(done)
      .catch(done.fail);
  });

  describe('clickCallback', () => {
    it('should show loading indicator while waiting', (done) => {
      const isChecked = true;
      const clickCallback = (newValue, toggleButton) => {
        const input = toggleButton.querySelector('.js-project-feature-toggle-input');

        expect(newValue).toEqual(false);

        // Check for the loading state
        expect(toggleButton.classList.contains('is-checked')).toEqual(false);
        expect(toggleButton.classList.contains('is-loading')).toEqual(true);
        expect(toggleButton.disabled).toEqual(true);
        expect(input.value).toEqual('true');

        // After the callback finishes, check that the loading state is gone
        getSetTimeoutPromise()
          .then(() => {
            expect(toggleButton.classList.contains('is-checked')).toEqual(false);
            expect(toggleButton.classList.contains('is-loading')).toEqual(false);
            expect(toggleButton.disabled).toEqual(false);
            expect(input.value).toEqual('false');
          })
          .then(done)
          .catch(done.fail);
      };

      const wrapper = setupFixture(isChecked, clickCallback);
      const toggleButton = wrapper.querySelector('.js-project-feature-toggle');

      toggleButton.click();
    });
  });
});
