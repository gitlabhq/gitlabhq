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

  context 'when the string is a Grape API description' do
    let(:page) { 'doc/api/custom_attributes.md' }

    before do
      described_class.anchors_by_docs_file = {}

      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(%r{\Adoc/}).and_return(false)
      allow(File).to receive(:exist?).with(page).and_return(true)

      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(page).and_return(<<~MARKDOWN)
        # Custom attributes

        ## Set a custom attribute
      MARKDOWN
    end

    context 'when the page it links to exists' do
      it 'does not register an offense for a `desc:` option' do
        expect_no_offenses(<<~RUBY)
          optional :with_custom_attributes, type: Boolean,
            desc: 'Includes [custom attributes](https://docs.gitlab.com/api/custom_attributes/).'
        RUBY
      end

      it 'does not register an offense for an anchor that exists' do
        expect_no_offenses(<<~RUBY)
          optional :with_custom_attributes, type: Boolean,
            desc: 'See [how to set one](https://docs.gitlab.com/api/custom_attributes/#set-a-custom-attribute).'
        RUBY
      end

      it 'does not register an offense when the link sits on a continuation line' do
        expect_no_offenses(<<~'RUBY')
          requires :glql_yaml, type: String, desc: 'GLQL query. See [custom ' \
                                                   'attributes](https://docs.gitlab.com/api/custom_attributes/).'
        RUBY
      end

      it 'does not register an offense for a `desc` summary' do
        expect_no_offenses(<<~RUBY)
          desc 'Lists the [custom attributes](https://docs.gitlab.com/api/custom_attributes/)'
        RUBY
      end

      it 'does not register an offense for a `detail` inside a `desc` block' do
        expect_no_offenses(<<~RUBY)
          desc 'Get an environment' do
            detail 'See [the docs](https://docs.gitlab.com/api/custom_attributes/).'
          end
        RUBY
      end

      it 'ignores the sentence punctuation that follows a bare link' do
        expect_no_offenses(<<~RUBY)
          optional :name, type: String,
            desc: 'See https://docs.gitlab.com/api/custom_attributes/.'
        RUBY
      end
    end

    context 'when only the section index page exists' do
      let(:index_page) { 'doc/api/rest/_index.md' }

      before do
        allow(File).to receive(:exist?).with(index_page).and_return(true)

        allow(File).to receive(:read).with(index_page).and_return(<<~MARKDOWN)
          # REST API

          ## Authentication
        MARKDOWN
      end

      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          optional :private_token, type: String,
            desc: 'See [authentication](https://docs.gitlab.com/api/rest/#authentication).'
        RUBY
      end
    end

    context 'when the page it links to does not exist' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          optional :with_custom_attributes, type: Boolean,
          desc: '[custom attributes](https://docs.gitlab.com/api/moved_away/)'
                                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This documentation page does not exist: `doc/api/moved_away.md`. An API [...]
        RUBY
      end
    end

    context 'when the anchor does not exist in the page' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          optional :with_custom_attributes, type: Boolean,
          desc: '[custom attributes](https://docs.gitlab.com/api/custom_attributes/#no-such-heading)'
                                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ The anchor `#no-such-heading` was not found in `doc/api/custom_attributes.md`.
        RUBY
      end
    end

    context 'when the link has no path' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          optional :name, type: String,
            desc: 'See the documentation at https://docs.gitlab.com/.'
        RUBY
      end
    end

    it 'still registers an offense for a neighbouring string that is not a description' do
      expect_offense(<<~RUBY)
        optional :name, type: String,
          desc: 'Name. See [the docs](https://docs.gitlab.com/api/custom_attributes/).',
          documentation: { example: 'https://docs.gitlab.com/api/custom_attributes/' }
                                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `#help_page_url` instead of directly including link. See [...]
      RUBY
    end
  end
end
