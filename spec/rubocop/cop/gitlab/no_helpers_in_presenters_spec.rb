# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/no_helpers_in_presenters'

RSpec.describe RuboCop::Cop::Gitlab::NoHelpersInPresenters, feature_category: :source_code_management do
  let(:doc_link) { 'https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/presenters/README.md#what-not-to-do-with-presenters' }
  let(:msg) { "Do not use helpers in presenters. Presenters are not aware of the view context. See #{doc_link}" }

  context 'when in presenter files' do
    context 'with include statements' do
      it 'registers an offense for including helper modules' do
        expect_offense(<<~RUBY, 'app/presenters/user_presenter.rb')
          class UserPresenter
            include ApplicationHelper
            ^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
          end
        RUBY
      end

      it 'registers an offense for including custom helper modules' do
        expect_offense(<<~RUBY, 'app/presenters/project_presenter.rb')
          class ProjectPresenter
            include UsersHelper
            ^^^^^^^^^^^^^^^^^^^ #{msg}
          end
        RUBY
      end

      it 'registers an offense for including modules ending with Helpers' do
        expect_offense(<<~RUBY, 'app/presenters/admin_presenter.rb')
          class AdminPresenter
            include FormattingHelpers
            ^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
          end
        RUBY
      end

      it 'registers an offense for including nested Rails helpers' do
        expect_offense(<<~RUBY, 'app/presenters/form_presenter.rb')
          class FormPresenter
            include ActionView::Helpers::FormHelper
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
          end
        RUBY
      end
    end

    context 'with extend statements' do
      it 'registers an offense for extending helper modules' do
        expect_offense(<<~RUBY, 'app/presenters/user_presenter.rb')
          class UserPresenter
            extend ApplicationHelper
            ^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
          end
        RUBY
      end

      it 'registers an offense for extending custom helper modules' do
        expect_offense(<<~RUBY, 'app/presenters/project_presenter.rb')
          class ProjectPresenter
            extend UsersHelper
            ^^^^^^^^^^^^^^^^^^ #{msg}
          end
        RUBY
      end
    end

    context 'with require statements' do
      it 'registers an offense for requiring helper files' do
        expect_offense(<<~RUBY, 'app/presenters/user_presenter.rb')
          require 'app/helpers/formatting_helper'
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}

          class UserPresenter
          end
        RUBY
      end

      it 'registers an offense for requiring files in helpers directory' do
        expect_offense(<<~RUBY, 'app/presenters/project_presenter.rb')
          require_relative '../helpers/user_helper'
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}

          class ProjectPresenter
          end
        RUBY
      end

      it 'registers an offense for requiring files ending with _helper' do
        expect_offense(<<~RUBY, 'app/presenters/admin_presenter.rb')
          require 'lib/custom_helper'
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}

          class AdminPresenter
          end
        RUBY
      end
    end

    context 'when no helpers are used' do
      it 'does not register an offense for clean presenters' do
        expect_no_offenses(<<~RUBY, 'app/presenters/user_presenter.rb')
          class UserPresenter
            def initialize(user)
              @user = user
            end

            def formatted_name
              user.name.upcase
            end

            private

            attr_reader :user
          end
        RUBY
      end

      it 'does not register an offense for including non-helper modules' do
        expect_no_offenses(<<~RUBY, 'app/presenters/project_presenter.rb')
          class ProjectPresenter
            include Enumerable
            include Comparable
          end
        RUBY
      end

      it 'does not register an offense for requiring non-helper files' do
        expect_no_offenses(<<~RUBY, 'app/presenters/admin_presenter.rb')
          require 'json'
          require 'lib/custom_formatter'

          class AdminPresenter
          end
        RUBY
      end
    end
  end
end
