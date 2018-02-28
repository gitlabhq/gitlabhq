import SecretValues from '~/behaviors/secret_values';

function generateFixtureMarkup(secrets, isRevealed) {
  return `
  <div class="js-secret-container">
    ${secrets.map(secret => `
      <div class="js-secret-value-placeholder">
        ***
      </div>
      <div class="hide js-secret-value">
        ${secret}
      </div>
    `).join('')}
    <button
      class="js-secret-value-reveal-button"
      data-secret-reveal-status="${isRevealed}"
    >
      ...
    </button>
  </div>
  `;
}

function setupSecretFixture(secrets, isRevealed) {
  const wrapper = document.createElement('div');
  wrapper.innerHTML = generateFixtureMarkup(secrets, isRevealed);

  const secretValues = new SecretValues(wrapper.querySelector('.js-secret-container'));
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

    it('should value hidden initially', () => {
      const wrapper = setupSecretFixture(secrets, false);
      const values = wrapper.querySelectorAll('.js-secret-value');
      const placeholders = wrapper.querySelectorAll('.js-secret-value-placeholder');

      expect(values.length).toEqual(1);
      expect(values[0].classList.contains('hide')).toEqual(true);
      expect(placeholders.length).toEqual(1);
      expect(placeholders[0].classList.contains('hide')).toEqual(false);
    });

    it('should toggle value and placeholder', () => {
      const wrapper = setupSecretFixture(secrets, false);
      const revealButton = wrapper.querySelector('.js-secret-value-reveal-button');
      const values = wrapper.querySelectorAll('.js-secret-value');
      const placeholders = wrapper.querySelectorAll('.js-secret-value-placeholder');

      revealButton.click();

      expect(values.length).toEqual(1);
      expect(values[0].classList.contains('hide')).toEqual(false);
      expect(placeholders.length).toEqual(1);
      expect(placeholders[0].classList.contains('hide')).toEqual(true);

      revealButton.click();

      expect(values.length).toEqual(1);
      expect(values[0].classList.contains('hide')).toEqual(true);
      expect(placeholders.length).toEqual(1);
      expect(placeholders[0].classList.contains('hide')).toEqual(false);
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
        expect(value.classList.contains('hide')).toEqual(true);
      });
      expect(placeholders.length).toEqual(3);
      placeholders.forEach((placeholder) => {
        expect(placeholder.classList.contains('hide')).toEqual(false);
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
        expect(value.classList.contains('hide')).toEqual(false);
      });
      expect(placeholders.length).toEqual(3);
      placeholders.forEach((placeholder) => {
        expect(placeholder.classList.contains('hide')).toEqual(true);
      });

      revealButton.click();

      expect(values.length).toEqual(3);
      values.forEach((value) => {
        expect(value.classList.contains('hide')).toEqual(true);
      });
      expect(placeholders.length).toEqual(3);
      placeholders.forEach((placeholder) => {
        expect(placeholder.classList.contains('hide')).toEqual(false);
      });
    });
  });
});
