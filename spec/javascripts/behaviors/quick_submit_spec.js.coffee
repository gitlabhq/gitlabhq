#= require behaviors/quick_submit

describe 'Quick Submit behavior', ->
  fixture.preload('behaviors/quick_submit.html')

  beforeEach ->
    fixture.load('behaviors/quick_submit.html')

    # Prevent a form submit from moving us off the testing page
    $('form').submit (e) -> e.preventDefault()

    @spies = {
      submit: spyOnEvent('form', 'submit')
    }

  it 'does not respond to other keyCodes', ->
    $('input').trigger(keydownEvent(keyCode: 32))

    expect(@spies.submit).not.toHaveBeenTriggered()

  it 'does not respond to Enter alone', ->
    $('input').trigger(keydownEvent(ctrlKey: false, metaKey: false))

    expect(@spies.submit).not.toHaveBeenTriggered()

  it 'does not respond to repeated events', ->
    $('input').trigger(keydownEvent(repeat: true))

    expect(@spies.submit).not.toHaveBeenTriggered()

  it 'disables submit buttons', ->
    $('textarea').trigger(keydownEvent())

    expect($('input[type=submit]')).toBeDisabled()
    expect($('button[type=submit]')).toBeDisabled()

  # We cannot stub `navigator.userAgent` for CI's `rake teaspoon` task, so we'll
  # only run the tests that apply to the current platform
  if navigator.userAgent.match(/Macintosh/)
    it 'responds to Meta+Enter', ->
      $('input').trigger(keydownEvent())

      expect(@spies.submit).toHaveBeenTriggered()

    it 'excludes other modifier keys', ->
      $('input').trigger(keydownEvent(altKey: true))
      $('input').trigger(keydownEvent(ctrlKey: true))
      $('input').trigger(keydownEvent(shiftKey: true))

      expect(@spies.submit).not.toHaveBeenTriggered()
  else
    it 'responds to Ctrl+Enter', ->
      $('input').trigger(keydownEvent())

      expect(@spies.submit).toHaveBeenTriggered()

    it 'excludes other modifier keys', ->
      $('input').trigger(keydownEvent(altKey: true))
      $('input').trigger(keydownEvent(metaKey: true))
      $('input').trigger(keydownEvent(shiftKey: true))

      expect(@spies.submit).not.toHaveBeenTriggered()

  keydownEvent = (options) ->
    if navigator.userAgent.match(/Macintosh/)
      defaults = { keyCode: 13, metaKey: true }
    else
      defaults = { keyCode: 13, ctrlKey: true }

    $.Event('keydown', $.extend({}, defaults, options))
