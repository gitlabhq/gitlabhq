#= require jquery.ui.all
#= require new_branch_form

describe 'Branch', ->
  describe 'create a new branch', ->
    fixture.preload('new_branch.html')

    beforeEach ->
      fixture.load('new_branch.html')
      $('form').on 'submit', (e) -> e.preventDefault()

      @form = new NewBranchForm($('.js-create-branch-form'), [])
      @name = $('.js-branch-name')

    it "can't start with a dot", ->
      @name.val('.foo').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't start with '.'")

    it "can't start with a slash", ->
      @name.val('/foo').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't start with '/'")

    it "can't have two consecutive dots", ->
      @name.val('foo..bar').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '..'")

    it "can't have spaces anywhere", ->
      @name.val(' foo').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain spaces")
      @name.val('foo bar').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain spaces")
      @name.val('foo ').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain spaces")

    it "can't have ~ anywhere", ->
      @name.val('~foo').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '~'")
      @name.val('foo~bar').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '~'")
      @name.val('foo~').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '~'")

    it "can't have tilde anwhere", ->
      @name.val('~foo').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '~'")
      @name.val('foo~bar').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '~'")
      @name.val('foo~').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '~'")

    it "can't have caret anywhere", ->
      @name.val('^foo').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '^'")
      @name.val('foo^bar').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '^'")
      @name.val('foo^').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '^'")

    it "can't have : anywhere", ->
      @name.val(':foo').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain ':'")
      @name.val('foo:bar').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain ':'")
      @name.val(':foo').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain ':'")

    it "can't have question mark anywhere", ->
      @name.val('?foo').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '?'")
      @name.val('foo?bar').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '?'")
      @name.val('foo?').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '?'")

    it "can't have asterisk anywhere", ->
      @name.val('*foo').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '*'")
      @name.val('foo*bar').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '*'")
      @name.val('foo*').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '*'")

    it "can't have open bracket anywhere", ->
      @name.val('[foo').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '['")
      @name.val('foo[bar').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '['")
      @name.val('foo[').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '['")

    it "can't have a backslash anywhere", ->
      @name.val('\\foo').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '\\'")
      @name.val('foo\\bar').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '\\'")
      @name.val('foo\\').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '\\'")

    it "can't contain a sequence @{ anywhere", ->
      @name.val('@{foo').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '@{'")
      @name.val('foo@{bar').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '@{'")
      @name.val('foo@{').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '@{'")

    it "can't have consecutive slashes", ->
      @name.val('foo//bar').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain consecutive slashes")

    it "can't end with a slash", ->
      @name.val('foo/').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't end in '/'")

    it "can't end with a dot", ->
      @name.val('foo.').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't end in '.'")

    it "can't end with .lock", ->
      @name.val('foo.lock').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't end in '.lock'")

    it "can't be the single character @", ->
      @name.val('@').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't be '@'")

    it "concatenates all error messages", ->
      @name.val('/foo bar?~.').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't start with '/', can't contain spaces, '?', '~', can't end in '.'")

    it "doesn't duplicate error messages", ->
      @name.val('?foo?bar?zoo?').trigger('blur')
      expect($('.js-branch-name-error span').text()).toEqual("can't contain '?'")

    it "removes the error message when is a valid name", ->
      @name.val('foo?bar').trigger('blur')
      expect($('.js-branch-name-error span').length).toEqual(1)
      @name.val('foobar').trigger('blur')
      expect($('.js-branch-name-error span').length).toEqual(0)

    it "can have dashes anywhere", ->
      @name.val('-foo-bar-zoo-').trigger('blur')
      expect($('.js-branch-name-error span').length).toEqual(0)

    it "can have underscores anywhere", ->
      @name.val('_foo_bar_zoo_').trigger('blur')
      expect($('.js-branch-name-error span').length).toEqual(0)

    it "can have numbers anywhere", ->
      @name.val('1foo2bar3zoo4').trigger('blur')
      expect($('.js-branch-name-error span').length).toEqual(0)

    it "can be only letters", ->
      @name.val('foo').trigger('blur')
      expect($('.js-branch-name-error span').length).toEqual(0)
