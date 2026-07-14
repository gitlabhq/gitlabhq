# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/api/access_level_string_type'

EXPOSE_MSG = "Do not document access level entity attributes as `type: 'Integer'`. " \
  "Use `type: 'String'` or a custom type instead to maintain API consistency."

RSpec.describe RuboCop::Cop::API::AccessLevelStringType, feature_category: :api do
  let(:param_msg) {  RuboCop::Cop::API::AccessLevelStringType::PARAM_MSG }

  let(:expose_msg) { RuboCop::Cop::API::AccessLevelStringType::EXPOSE_MSG }

  context 'when using Integer type for an access level parameter with requires' do
    it 'adds an offense for :access_level' do
      expect_offense(<<~RUBY)
        params do
          requires :access_level, type: Integer, desc: 'A valid access level'
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{param_msg}
        end
      RUBY
    end

    it 'adds an offense for :access_level_execute (prefix)' do
      expect_offense(<<~RUBY)
        params do
          requires :access_level_execute, type: Integer
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{param_msg}
        end
      RUBY
    end

    it 'adds an offense for :min_access_level (suffix)' do
      expect_offense(<<~RUBY)
        params do
          requires :min_access_level, type: Integer
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{param_msg}
        end
      RUBY
    end
  end

  context 'when using Integer type for an access level parameter with optional' do
    it 'adds an offense for :access_level' do
      expect_offense(<<~RUBY)
        params do
          optional :access_level, type: Integer, desc: 'A valid access level'
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{param_msg}
        end
      RUBY
    end

    it 'adds an offense for :push_access_level (suffix)' do
      expect_offense(<<~RUBY)
        params do
          optional :push_access_level, type: Integer
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{param_msg}
        end
      RUBY
    end

    it 'adds an offense for :minimum_access_level_execute (mid-name)' do
      expect_offense(<<~RUBY)
        params do
          optional :minimum_access_level_execute, type: Integer
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{param_msg}
        end
      RUBY
    end
  end

  context 'when using a string parameter name' do
    it 'adds an offense' do
      expect_offense(<<~RUBY)
        params do
          requires 'access_level', type: Integer, desc: 'A valid access level'
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{param_msg}
        end
      RUBY
    end
  end

  context 'when using top-level ::Integer constant' do
    it 'adds an offense' do
      expect_offense(<<~RUBY)
        params do
          requires :access_level, type: ::Integer
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{param_msg}
        end
      RUBY
    end
  end

  context 'when using safe-navigation operator' do
    it 'adds an offense' do
      expect_offense(<<~RUBY)
        params do
          foo&.requires :access_level, type: Integer
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{param_msg}
        end
      RUBY
    end
  end

  context 'when using types: with Integer in the array' do
    it 'adds an offense for types: [Integer]' do
      expect_offense(<<~RUBY)
        params do
          requires :access_level, types: [Integer]
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{param_msg}
        end
      RUBY
    end

    it 'adds an offense for types: [Integer, String]' do
      expect_offense(<<~RUBY)
        params do
          requires :access_level, types: [Integer, String], desc: 'A valid access level'
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{param_msg}
        end
      RUBY
    end

    it 'adds an offense for types: [String, Integer]' do
      expect_offense(<<~RUBY)
        params do
          optional :access_level, types: [String, Integer]
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{param_msg}
        end
      RUBY
    end

    it 'adds an offense for types: [::Integer, String]' do
      expect_offense(<<~RUBY)
        params do
          requires :access_level, types: [::Integer, String]
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{param_msg}
        end
      RUBY
    end

    it 'adds an offense for access_level variant names' do
      expect_offense(<<~RUBY)
        params do
          optional :min_access_level, types: [Integer, String]
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{param_msg}
        end
      RUBY
    end
  end

  context 'when using types: without Integer' do
    it 'does not add an offense' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :access_level, types: [String]
        end
      RUBY
    end

    it 'does not add an offense for multiple non-Integer types' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :access_level, types: [String, CustomType]
        end
      RUBY
    end
  end

  context 'when not an access level parameter' do
    it 'does not add an offense' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :per_page, type: Integer, desc: 'Number of items per page'
        end
      RUBY
    end
  end

  context 'when access_level has no type key' do
    it 'does not add an offense' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :access_level, desc: 'A valid access level'
        end
      RUBY
    end
  end

  context 'when access_level uses a non-Integer type' do
    it 'does not add an offense' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :access_level, type: String, desc: 'A valid access level'
        end
      RUBY
    end
  end

  context 'when access_level param has a non-hash second argument' do
    it 'does not add an offense' do
      # This syntax is invalid, so it gets picked up by other cops
      expect_no_offenses(<<~RUBY)
        params do
          requires :access_level, Integer
        end
      RUBY
    end
  end

  context 'when exposing an access level entity attribute as Integer' do
    it 'adds an offense for :access_level' do
      expect_offense(<<~RUBY)
        class Entity < Grape::Entity
          expose :access_level, documentation: { type: 'Integer', example: 40 }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expose_msg}
        end
      RUBY
    end

    it 'adds an offense for variant names like :base_access_level' do
      expect_offense(<<~RUBY)
        class Entity < Grape::Entity
          expose :base_access_level, documentation: { type: 'Integer' }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expose_msg}
        end
      RUBY
    end

    it 'adds an offense for a string attribute name' do
      expect_offense(<<~RUBY)
        class Entity < Grape::Entity
          expose 'access_level', documentation: { type: 'Integer' }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expose_msg}
        end
      RUBY
    end

    it 'adds an offense when the attribute is aliased via :as' do
      expect_offense(<<~RUBY)
        class Entity < Grape::Entity
          expose :group_access, as: :group_access_level, documentation: { type: 'Integer' }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expose_msg}
        end
      RUBY
    end

    it 'adds an offense when the attribute is aliased via :as with a string value' do
      expect_offense(<<~RUBY)
        class Entity < Grape::Entity
          expose :group_access, as: 'group_access_level', documentation: { type: 'Integer' }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expose_msg}
        end
      RUBY
    end

    it 'adds an offense when an access level attribute is aliased to a non-access-level name' do
      expect_offense(<<~RUBY)
        class Entity < Grape::Entity
          expose :group_access_level, as: :group_id, documentation: { type: 'Integer' }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expose_msg}
        end
      RUBY
    end

    it 'adds an offense when expose has a block' do
      expect_offense(<<~RUBY)
        class Entity < Grape::Entity
          expose :group_access_level, documentation: { type: 'Integer', example: 50 } do |group, options|
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expose_msg}
            group.access_level
          end
        end
      RUBY
    end

    it 'adds an offense for a richer documentation hash' do
      expect_offense(<<~RUBY)
        class Entity < Grape::Entity
          expose :access_level, documentation: {
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expose_msg}
            type: 'Integer',
            example: 40,
            description: 'Access level.',
            values: [10, 20, 30, 40, 50]
          }
        end
      RUBY
    end

    it 'adds an offense when one of multiple exposed attributes is an access level' do
      expect_offense(<<~RUBY)
        class Entity < Grape::Entity
          expose :access_level, :other_field, documentation: { type: 'Integer' }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expose_msg}
        end
      RUBY
    end
  end

  context 'when exposing an access level entity attribute with a non-Integer documented type' do
    it 'does not add an offense for type: String' do
      expect_no_offenses(<<~RUBY)
        class Entity < Grape::Entity
          expose :access_level, documentation: { type: 'String', example: 'maintainer' }
        end
      RUBY
    end

    it 'does not add an offense for a custom type' do
      expect_no_offenses(<<~RUBY)
        class Entity < Grape::Entity
          expose :access_level, documentation: { type: 'AccessLevel' }
        end
      RUBY
    end
  end

  context 'when exposing an access level entity attribute without documentation' do
    it 'does not add an offense' do
      expect_no_offenses(<<~RUBY)
        class Entity < Grape::Entity
          expose :access_level
        end
      RUBY
    end

    it 'does not add an offense when other options are present' do
      expect_no_offenses(<<~RUBY)
        class Entity < Grape::Entity
          expose :access_level, if: ->(x) { x.visible? }
        end
      RUBY
    end
  end

  context 'when exposing a non-access-level attribute as Integer' do
    it 'does not add an offense' do
      expect_no_offenses(<<~RUBY)
        class Entity < Grape::Entity
          expose :id, documentation: { type: 'Integer', example: 1 }
        end
      RUBY
    end

    it 'does not add an offense when aliased to a non-access-level name' do
      expect_no_offenses(<<~RUBY)
        class Entity < Grape::Entity
          expose :group_access, as: :group_id, documentation: { type: 'Integer' }
        end
      RUBY
    end
  end
end
