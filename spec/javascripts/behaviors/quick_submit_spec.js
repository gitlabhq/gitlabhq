import $ from 'jquery';
import '~/behaviors/quick_submit';

describe('Quick Submit behavior', () => {
  const keydownEvent = (options = { keyCode: 13, metaKey: true }) => $.Event('keydown', options);

  preloadFixtures('merge_requests/merge_request_with_task_list.html.raw');

  beforeEach(() => {
    loadFixtures('merge_requests/merge_request_with_task_list.html.raw');
    $('body').attr('data-page', 'projects:merge_requests:show');
    $('form').submit((e) => {
      // Prevent a form submit from moving us off the testing page
      e.preventDefault();
    });
    this.spies = {
      submit: spyOnEvent('form', 'submit'),
    };

    this.textarea = $('.js-quick-submit textarea').first();
  });

  afterEach(() => {
    // Undo what we did to the shared <body>
    $('body').removeAttr('data-page');
  });

  it('does not respond to other keyCodes', () => {
    this.textarea.trigger(keydownEvent({
      keyCode: 32,
    }));
    expect(this.spies.submit).not.toHaveBeenTriggered();
  });

  it('does not respond to Enter alone', () => {
    this.textarea.trigger(keydownEvent({
      ctrlKey: false,
      metaKey: false,
    }));
    expect(this.spies.submit).not.toHaveBeenTriggered();
  });

  it('does not respond to repeated events', () => {
    this.textarea.trigger(keydownEvent({
      repeat: true,
    }));
    expect(this.spies.submit).not.toHaveBeenTriggered();
  });

  it('disables input of type submit', () => {
    const submitButton = $('.js-quick-submit input[type=submit]');
    this.textarea.trigger(keydownEvent());

    expect(submitButton).toBeDisabled();
  });
  it('disables button of type submit', () => {
    const submitButton = $('.js-quick-submit input[type=submit]');
    this.textarea.trigger(keydownEvent());

    expect(submitButton).toBeDisabled();
  });
  it('only clicks one submit', () => {
    const existingSubmit = $('.js-quick-submit input[type=submit]');
    // Add an extra submit button
    const newSubmit = $('<button type="submit">Submit it</button>');
    newSubmit.insertAfter(this.textarea);

    const oldClick = spyOnEvent(existingSubmit, 'click');
    const newClick = spyOnEvent(newSubmit, 'click');

    this.textarea.trigger(keydownEvent());

    expect(oldClick).not.toHaveBeenTriggered();
    expect(newClick).toHaveBeenTriggered();
  });
  // We cannot stub `navigator.userAgent` for CI's `rake karma` task, so we'll
  // only run the tests that apply to the current platform
  if (navigator.userAgent.match(/Macintosh/)) {
    describe('In Macintosh', () => {
      it('responds to Meta+Enter', () => {
        this.textarea.trigger(keydownEvent());
        return expect(this.spies.submit).toHaveBeenTriggered();
      });

      it('excludes other modifier keys', () => {
        this.textarea.trigger(keydownEvent({
          altKey: true,
        }));
        this.textarea.trigger(keydownEvent({
          ctrlKey: true,
        }));
        this.textarea.trigger(keydownEvent({
          shiftKey: true,
        }));
        return expect(this.spies.submit).not.toHaveBeenTriggered();
      });
    });
  } else {
    it('responds to Ctrl+Enter', () => {
      this.textarea.trigger(keydownEvent());
      return expect(this.spies.submit).toHaveBeenTriggered();
    });

    it('excludes other modifier keys', () => {
      this.textarea.trigger(keydownEvent({
        altKey: true,
      }));
      this.textarea.trigger(keydownEvent({
        metaKey: true,
      }));
      this.textarea.trigger(keydownEvent({
        shiftKey: true,
      }));
      return expect(this.spies.submit).not.toHaveBeenTriggered();
    });
  }
});
