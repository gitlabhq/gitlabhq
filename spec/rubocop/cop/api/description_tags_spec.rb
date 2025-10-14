# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/api/description_tags'

RSpec.describe RuboCop::Cop::API::DescriptionTags, :config, feature_category: :api do
  def expect_offense(source, file = 'lib/api/environments.rb')
    super
  end

  context 'when in API context' do
    context 'when desc block has tags' do
      it 'does not register an offense with array literal tags' do
        expect_no_offenses(<<~RUBY)
          desc 'Get a specific environment' do
            success Entities::Environment
            failure [
              { code: 401, message: 'Unauthorized' },
              { code: 404, message: 'Not found' }
            ]
            tags %w[environments]
          end
        RUBY
      end

      it 'does not register an offense with variable tags' do
        expect_no_offenses(<<~RUBY)
          desc 'Create a new environment' do
            detail 'Creates a new environment'
            tags environments_tags
          end
        RUBY
      end

      it 'does not register an offense with method call tags' do
        expect_no_offenses(<<~RUBY)
          desc 'Update environment' do
            success Entities::Environment
            tags get_environment_tags
          end
        RUBY
      end

      it 'does not register an offense with string array tags' do
        expect_no_offenses(<<~RUBY)
          desc 'Delete environment' do
            success Entities::Environment
            tags ['environments', 'admin']
          end
        RUBY
      end
    end

    context 'when desc block does not have tags' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          desc 'Get a specific environment' do
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ API desc blocks must define tags. See https://docs.gitlab.com/development/api_styleguide#choosing-a-tag.
            success Entities::Environment
            failure [
              { code: 401, message: 'Unauthorized' },
              { code: 404, message: 'Not found' }
            ]
          end
        RUBY

        expect_correction(<<~RUBY)
          desc 'Get a specific environment' do
            success Entities::Environment
            failure [
              { code: 401, message: 'Unauthorized' },
              { code: 404, message: 'Not found' }
            ]
            tags %w[environments]
          end
        RUBY
      end

      it 'registers an offense for desc block with only success in subfolder' do
        expect_offense(<<~RUBY, 'ee/lib/ee/environments.rb')
          desc 'Simple endpoint' do
          ^^^^^^^^^^^^^^^^^^^^^^ API desc blocks must define tags. See https://docs.gitlab.com/development/api_styleguide#choosing-a-tag.
            success Entities::Simple
          end
        RUBY

        expect_correction(<<~RUBY)
          desc 'Simple endpoint' do
            success Entities::Simple
            tags %w[environments]
          end
        RUBY
      end

      it 'registers an offense for desc block with only success' do
        expect_offense(<<~RUBY)
          desc 'Simple endpoint' do
          ^^^^^^^^^^^^^^^^^^^^^^ API desc blocks must define tags. See https://docs.gitlab.com/development/api_styleguide#choosing-a-tag.
            success Entities::Simple
          end
        RUBY

        expect_correction(<<~RUBY)
          desc 'Simple endpoint' do
            success Entities::Simple
            tags %w[environments]
          end
        RUBY
      end

      it 'registers an offense for desc block with detail but no tags' do
        expect_offense(<<~RUBY)
          desc 'Complex endpoint' do
          ^^^^^^^^^^^^^^^^^^^^^^^ API desc blocks must define tags. See https://docs.gitlab.com/development/api_styleguide#choosing-a-tag.
            detail 'This is a complex endpoint'
            success Entities::Complex
            failure [{ code: 500, message: 'Server Error' }]
          end
        RUBY

        expect_correction(<<~RUBY)
          desc 'Complex endpoint' do
            detail 'This is a complex endpoint'
            success Entities::Complex
            failure [{ code: 500, message: 'Server Error' }]
            tags %w[environments]
          end
        RUBY
      end

      it 'registers an offence for detail block using heredoc' do
        expect_offense(<<~RUBY)
          desc 'Complex endpoint' do
          ^^^^^^^^^^^^^^^^^^^^^^^ API desc blocks must define tags. See https://docs.gitlab.com/development/api_styleguide#choosing-a-tag.
            detail <<~END
              This feature was introduced in GitLab 12.7.

              This will only ever increase the number of indexed namespaces. Providing a value lower than the current rolled out percentage will have no effect.

              This percentage is never persisted but is used to calculate the number of new namespaces to rollout.

              If the same percentage is applied again at a later time, due to possible new namespaces being created during the period, some of them will also be indexed. Therefore you may expect that setting this to 10%, then waiting a month and setting to 10% again will trigger new namespaces to be added (i.e. 10% of the number of newly created namespaces in the last month within the given plan).
            END
          end
        RUBY

        expect_correction(<<~RUBY)
          desc 'Complex endpoint' do
            detail <<~END
              This feature was introduced in GitLab 12.7.

              This will only ever increase the number of indexed namespaces. Providing a value lower than the current rolled out percentage will have no effect.

              This percentage is never persisted but is used to calculate the number of new namespaces to rollout.

              If the same percentage is applied again at a later time, due to possible new namespaces being created during the period, some of them will also be indexed. Therefore you may expect that setting this to 10%, then waiting a month and setting to 10% again will trigger new namespaces to be added (i.e. 10% of the number of newly created namespaces in the last month within the given plan).
            END
            tags %w[environments]
          end
        RUBY
      end
    end

    context 'when desc has arguments and block' do
      it 'does not register an offense when tags are present' do
        expect_no_offenses(<<~RUBY)
          desc 'Get environment', entity: Entities::Environment do
            success Entities::Environment
            tags %w[environments]
          end
        RUBY
      end
    end

    context 'when desc is called without a block' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          desc 'Simple description without block'
        RUBY
      end
    end

    context 'when tags is called in nested context' do
      it 'does not register an offense when tags are in the desc block' do
        expect_no_offenses(<<~RUBY)
          desc 'Nested example' do
            success Entities::Environment
            if condition
              tags %w[conditional]
            else
              tags %w[default]
            end
          end
        RUBY
      end

      it 'does not register an offense when tags are in a method call within desc block' do
        expect_no_offenses(<<~RUBY)
          desc 'Method call example' do
            success Entities::Environment
            configure_endpoint do
              tags %w[configured]
            end
          end
        RUBY
      end
    end
  end

  context 'when desc is called on an object' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        object.desc 'Method call on object' do
          success Entities::Something
        end
      RUBY
    end
  end

  context 'with multiple desc blocks' do
    it 'registers offenses for blocks without tags and ignores blocks with tags' do
      expect_offense(<<~RUBY)
        desc 'First endpoint' do
        ^^^^^^^^^^^^^^^^^^^^^ API desc blocks must define tags. See https://docs.gitlab.com/development/api_styleguide#choosing-a-tag.
          success Entities::First
        end

        desc 'Second endpoint' do
          success Entities::Second
          tags %w[second]
        end

        desc 'Third endpoint' do
        ^^^^^^^^^^^^^^^^^^^^^ API desc blocks must define tags. See https://docs.gitlab.com/development/api_styleguide#choosing-a-tag.
          success Entities::Third
          failure [{ code: 404, message: 'Not found' }]
        end
      RUBY

      expect_correction(<<~RUBY)
        desc 'First endpoint' do
          success Entities::First
          tags %w[environments]
        end

        desc 'Second endpoint' do
          success Entities::Second
          tags %w[second]
        end

        desc 'Third endpoint' do
          success Entities::Third
          failure [{ code: 404, message: 'Not found' }]
          tags %w[environments]
        end
      RUBY
    end
  end
end
