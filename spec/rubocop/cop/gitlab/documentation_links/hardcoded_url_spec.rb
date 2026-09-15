# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../../rubocop/cop/gitlab/documentation_links/hardcoded_url'

RSpec.describe RuboCop::Cop::Gitlab::DocumentationLinks::HardcodedUrl, feature_category: :shared do
  context 'when string literal is added with docs url prefix' do
    context 'when inlined' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          'See [the docs](https://docs.gitlab.com/ee/user/permissions#roles).'
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `#help_page_url` instead of directly including link. See [...]
        RUBY
      end
    end

    context 'when multilined' do
      it 'registers an offense' do
        expect_offense(<<~'RUBY')
          'See the docs: ' \
          'https://docs.gitlab.com/ee/user/permissions#roles'
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `#help_page_url` instead of directly including link. See [...]
        RUBY
      end
    end

    context 'with heredoc' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          <<-HEREDOC
            See the docs:
            https://docs.gitlab.com/ee/user/permissions#roles
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `#help_page_url` instead of directly including link. See [...]
          HEREDOC
        RUBY
      end
    end
  end

  context 'when string literal is added without the /ee/ prefix' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        'See [the docs](https://docs.gitlab.com/user/permissions/#roles).'
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `#help_page_url` instead of directly including link. See [...]
      RUBY
    end
  end

  context 'when string literal is added without docs url prefix' do
    context 'when inlined' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          '[The DevSecOps Platform](https://about.gitlab.com/)'
        RUBY
      end
    end

    context 'when multilined' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          'The DevSecOps Platform: ' \
          'https://about.gitlab.com/'
        RUBY
      end
    end

    context 'with heredoc' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          <<-HEREDOC
            The DevSecOps Platform:
            https://about.gitlab.com/
          HEREDOC
        RUBY
      end
    end
  end

  context 'when linking to docs that live in a separate repository' do
    it 'does not register an offense for GitLab Runner docs' do
      expect_no_offenses(<<~RUBY)
        'See [the docs](https://docs.gitlab.com/runner/install/).'
      RUBY
    end

    it 'does not register an offense for Linux package (Omnibus) docs' do
      expect_no_offenses(<<~RUBY)
        'See [the docs](https://docs.gitlab.com/omnibus/settings/configuration.html).'
      RUBY
    end

    it 'does not register an offense for GitLab Charts docs' do
      expect_no_offenses(<<~RUBY)
        'See [the docs](https://docs.gitlab.com/charts/charts/globals).'
      RUBY
    end
  end
end
