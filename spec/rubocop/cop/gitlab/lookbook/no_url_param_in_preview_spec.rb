# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../../rubocop/cop/gitlab/lookbook/no_url_param_in_preview'

RSpec.describe RuboCop::Cop::Gitlab::Lookbook::NoUrlParamInPreview, feature_category: :tooling do
  context 'when @param has url input type' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # @param foo url
        ^^^^^^^^^^^^^^^^ Do not expose URL/link parameters via `@param` in Lookbook previews. [...]
        def default(href: "#")
        end
      RUBY
    end
  end

  context 'when @param name contains "link"' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # @param primary_button_link text
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not expose URL/link parameters via `@param` in Lookbook previews. [...]
        def default(primary_button_link: "#")
        end
      RUBY
    end
  end

  context 'when @param name contains "href"' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # @param href text
        ^^^^^^^^^^^^^^^^^^ Do not expose URL/link parameters via `@param` in Lookbook previews. [...]
        def default(href: "#")
        end
      RUBY
    end
  end

  context 'when @param name contains "url"' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # @param redirect_url text
        ^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not expose URL/link parameters via `@param` in Lookbook previews. [...]
        def default(redirect_url: "#")
        end
      RUBY
    end
  end

  context 'when @param does not involve URLs' do
    it 'does not register an offense for text params' do
      expect_no_offenses(<<~RUBY)
        # @param title text
        def default(title: "Hello")
        end
      RUBY
    end

    it 'does not register an offense for select params' do
      expect_no_offenses(<<~RUBY)
        # @param icon select [~, star-o, tanuki]
        def default(icon: :tanuki)
        end
      RUBY
    end

    it 'does not register an offense for toggle params' do
      expect_no_offenses(<<~RUBY)
        # @param compact toggle
        def default(compact: false)
        end
      RUBY
    end

    it 'does not register an offense for button_text' do
      expect_no_offenses(<<~RUBY)
        # @param button_text text
        def default(button_text: "Click")
        end
      RUBY
    end
  end
end
