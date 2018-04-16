import SecretValues from '~/behaviors/secret_values';

function generateValueMarkup(
  secret,
  valueClass = 'js-secret-value',
  placeholderClass = 'js-secret-value-placeholder',
) {
  return `
    <div class="${placeholderClass}">
      ***
    </div>
    <div class="hidden ${valueClass}">
      ${secret}
    </div>
  `;
}

function generateFixtureMarkup(secrets, isRevealed, valueClass, placeholderClass) {
  return `
  <div class="js-secret-container">
    ${secrets.map(secret => generateValueMarkup(secret, valueClass, placeholderClass)).join('')}
    <button
      class="js-secret-value-reveal-button"
      data-secret-reveal-status="${isRevealed}"
    >
      ...
    </button>
  </div>
  `;
}

function setupSecretFixture(
  secrets,
  isRevealed,
  valueClass = 'js-secret-value',
  placeholderClass = 'js-secret-value-placeholder',
) {
  const wrapper = document.createElement('div');
  wrapper.innerHTML = generateFixtureMarkup(
    secrets,
    isRevealed,
    valueClass,
    placeholderClass,
  );

  const secretValues = new SecretValues({
    container: wrapper.querySelector('.js-secret-container'),
    valueSelector: `.${valueClass}`,
    placeholderSelector: `.${placeholderClass}`,
  });
  secretValues.init();

  return wrapper;
}

describe('setupSecretValues', () => {
  describe('with a single secret', () => {
    const secrets = ['mysecret123'];

    it('should have correct "Reveal" label when values are hidden', () => {
      const wrapper = setupSecretFixture(secrets, false);
      const revealButton = wrapper.querySelector('.js-secret-value-reveal-button');

      expect(revealButton.textContent).toEqual('Reveal value');
    });

    it('should have correct "Hide" label when values are shown', () => {
      const wrapper = setupSecretFixture(secrets, true);
      const revealButton = wrapper.querySelector('.js-secret-value-reveal-button');

      expect(revealButton.textContent).toEqual('Hide value');
    });

    it('should have value hidden initially', () => {
      const wrapper = setupSecretFixture(secrets, false);
      const values = wrapper.querySelectorAll('.js-secret-value');
      const placeholders = wrapper.querySelectorAll('.js-secret-value-placeholder');

      expect(values.length).toEqual(1);
      expect(values[0].classList.contains('hidden')).toEqual(true);
      expect(placeholders.length).toEqual(1);
      expect(placeholders[0].classList.contains('hidden')).toEqual(false);
    });

    it('should toggle value and placeholder', () => {
      const wrapper = setupSecretFixture(secrets, false);
      const revealButton = wrapper.querySelector('.js-secret-value-reveal-button');
      const values = wrapper.querySelectorAll('.js-secret-value');
      const placeholders = wrapper.querySelectorAll('.js-secret-value-placeholder');

      revealButton.click();

      expect(values.length).toEqual(1);
      expect(values[0].classList.contains('hidden')).toEqual(false);
      expect(placeholders.length).toEqual(1);
      expect(placeholders[0].classList.contains('hidden')).toEqual(true);

      revealButton.click();

      expect(values.length).toEqual(1);
      expect(values[0].classList.contains('hidden')).toEqual(true);
      expect(placeholders.length).toEqual(1);
      expect(placeholders[0].classList.contains('hidden')).toEqual(false);
    });
  });

  describe('with a multiple secrets', () => {
    const secrets = ['mysecret123', 'happygoat456', 'tanuki789'];

    it('should have correct "Reveal" label when values are hidden', () => {
      const wrapper = setupSecretFixture(secrets, false);
      const revealButton = wrapper.querySelector('.js-secret-value-reveal-button');

      expect(revealButton.textContent).toEqual('Reveal values');
    });

    it('should have correct "Hide" label when values are shown', () => {
      const wrapper = setupSecretFixture(secrets, true);
      const revealButton = wrapper.querySelector('.js-secret-value-reveal-button');

      expect(revealButton.textContent).toEqual('Hide values');
    });

    it('should have all values hidden initially', () => {
      const wrapper = setupSecretFixture(secrets, false);
      const values = wrapper.querySelectorAll('.js-secret-value');
      const placeholders = wrapper.querySelectorAll('.js-secret-value-placeholder');

      expect(values.length).toEqual(3);
      values.forEach((value) => {
        expect(value.classList.contains('hidden')).toEqual(true);
      });
      expect(placeholders.length).toEqual(3);
      placeholders.forEach((placeholder) => {
        expect(placeholder.classList.contains('hidden')).toEqual(false);
      });
    });

    it('should toggle values and placeholders', () => {
      const wrapper = setupSecretFixture(secrets, false);
      const revealButton = wrapper.querySelector('.js-secret-value-reveal-button');
      const values = wrapper.querySelectorAll('.js-secret-value');
      const placeholders = wrapper.querySelectorAll('.js-secret-value-placeholder');

      revealButton.click();

      expect(values.length).toEqual(3);
      values.forEach((value) => {
        expect(value.classList.contains('hidden')).toEqual(false);
      });
      expect(placeholders.length).toEqual(3);
      placeholders.forEach((placeholder) => {
        expect(placeholder.classList.contains('hidden')).toEqual(true);
      });

      revealButton.click();

      expect(values.length).toEqual(3);
      values.forEach((value) => {
        expect(value.classList.contains('hidden')).toEqual(true);
      });
      expect(placeholders.length).toEqual(3);
      placeholders.forEach((placeholder) => {
        expect(placeholder.classList.contains('hidden')).toEqual(false);
      });
    });
  });

  describe('with dynamic secrets', () => {
    const secrets = ['mysecret123', 'happygoat456', 'tanuki789'];

    it('should toggle values and placeholders', () => {
      const wrapper = setupSecretFixture(secrets, false);
      // Insert the new dynamic row
      wrapper.querySelector('.js-secret-container').insertAdjacentHTML('afterbegin', generateValueMarkup('foobarbazdynamic'));

      const revealButton = wrapper.querySelector('.js-secret-value-reveal-button');
      const values = wrapper.querySelectorAll('.js-secret-value');
      const placeholders = wrapper.querySelectorAll('.js-secret-value-placeholder');

      revealButton.click();

      expect(values.length).toEqual(4);
      values.forEach((value) => {
        expect(value.classList.contains('hidden')).toEqual(false);
      });
      expect(placeholders.length).toEqual(4);
      placeholders.forEach((placeholder) => {
        expect(placeholder.classList.contains('hidden')).toEqual(true);
      });

      revealButton.click();

      expect(values.length).toEqual(4);
      values.forEach((value) => {
        expect(value.classList.contains('hidden')).toEqual(true);
      });
      expect(placeholders.length).toEqual(4);
      placeholders.forEach((placeholder) => {
        expect(placeholder.classList.contains('hidden')).toEqual(false);
      });
    });
  });

  describe('selector options', () => {
    const secrets = ['mysecret123'];

    it('should respect `valueSelector` and `placeholderSelector` options', () => {
      const valueClass = 'js-some-custom-placeholder-selector';
      const placeholderClass = 'js-some-custom-value-selector';

      const wrapper = setupSecretFixture(secrets, false, valueClass, placeholderClass);
      const values = wrapper.querySelectorAll(`.${valueClass}`);
      const placeholders = wrapper.querySelectorAll(`.${placeholderClass}`);
      const revealButton = wrapper.querySelector('.js-secret-value-reveal-button');

      expect(values.length).toEqual(1);
      expect(placeholders.length).toEqual(1);

      revealButton.click();

      expect(values.length).toEqual(1);
      expect(values[0].classList.contains('hidden')).toEqual(false);
      expect(placeholders.length).toEqual(1);
      expect(placeholders[0].classList.contains('hidden')).toEqual(true);
    });
  });
});
