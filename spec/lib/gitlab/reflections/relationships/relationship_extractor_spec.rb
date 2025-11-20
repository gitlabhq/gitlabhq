# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Reflections::Relationships::RelationshipExtractor, feature_category: :database do
  let_it_be(:extractor) { described_class.new }

  shared_examples 'extracted relationships' do
    it 'returns an array of relationships' do
      expect(relationships).to be_an(Array)
      expect(relationships).to all(be_a(Gitlab::Reflections::Relationships::Relationship))
    end
  end

  shared_examples 'relationship with expected attributes' do
    it "has a relationship with correct attributse" do
      expect(relationships).to include(have_attributes(expected_attributes))
    end
  end

  describe '#extract' do
    # Establish a TestModel with associations defined through the `reflections` attribute.
    # The reflections are set per spec context. E.g. has_many vs belongs_to.
    subject(:relationships) { extractor.extract }

    let(:mock_models) { [test_model_class] }
    let(:test_model_class) do
      # rubocop:disable RSpec/VerifiedDoubles -- Using generic mock objects
      double(
        'TestModel',
        name: 'TestModel',
        table_name: 'test_models',
        primary_key: 'id',
        reflections: test_reflections
      )
      # rubocop:enable RSpec/VerifiedDoubles
    end

    let(:test_reflections) { { reflection_name => reflection } }

    let(:reflection) do # -- Using generic mock objects for ActiveRecord reflections
      instance_double(reflection_class, **reflection_attributes)
    end

    before do
      allow(Gitlab::Reflections::Models::ActiveRecord.instance).to receive(:models).and_return(mock_models)
    end

    context 'with belongs_to associations' do
      let(:reflection_name) { 'user' }
      let(:reflection_class) { ActiveRecord::Reflection::BelongsToReflection }
      let(:reflection_attributes) do
        {
          name: :user,
          macro: :belongs_to,
          # rubocop:disable RSpec/VerifiedDoubles -- Using generic mock objects
          klass: double('User', name: 'User', table_name: 'users'),
          # rubocop:enable RSpec/VerifiedDoubles
          polymorphic?: false,
          through_reflection?: false,
          options: {},
          association_primary_key: 'id',
          foreign_key: 'user_id'
        }
      end

      it_behaves_like 'extracted relationships'

      it_behaves_like 'relationship with expected attributes' do
        let(:expected_attributes) do
          {
            parent_table: 'users',
            child_table: 'test_models',
            relationship_type: 'many_to_one',
            child_association: include(type: 'belongs_to', name: 'user')
          }
        end
      end
    end

    context 'with has_many associations' do
      let(:reflection_name) { 'posts' }
      let(:reflection_class) { ActiveRecord::Reflection::HasManyReflection }
      let(:reflection_attributes) do
        {
          name: :posts,
          macro: :has_many,
          # rubocop:disable RSpec/VerifiedDoubles -- Using generic mock objects
          klass: double('Post', name: 'Post', table_name: 'posts'),
          # rubocop:enable RSpec/VerifiedDoubles
          polymorphic?: false,
          through_reflection?: false,
          options: {},
          foreign_key: 'test_model_id',
          active_record_primary_key: 'id'
        }
      end

      it_behaves_like 'extracted relationships'

      it_behaves_like 'relationship with expected attributes' do
        let(:expected_attributes) do
          {
            parent_table: 'test_models',
            child_table: 'posts',
            relationship_type: 'one_to_many',
            parent_association: include(type: 'has_many', name: 'posts')
          }
        end
      end
    end

    context 'with has_one associations' do
      let(:reflection_name) { 'profile' }
      let(:reflection_class) { ActiveRecord::Reflection::HasOneReflection }
      let(:reflection_attributes) do
        {
          name: :profile,
          macro: :has_one,
          # rubocop:disable RSpec/VerifiedDoubles -- Using generic mock objects
          klass: double('Profile', name: 'Profile', table_name: 'profiles'),
          # rubocop:enable RSpec/VerifiedDoubles
          polymorphic?: false,
          through_reflection?: false,
          options: {},
          foreign_key: 'test_model_id',
          active_record_primary_key: 'id'
        }
      end

      it_behaves_like 'extracted relationships'

      it_behaves_like 'relationship with expected attributes' do
        let(:expected_attributes) do
          {
            parent_table: 'test_models',
            child_table: 'profiles',
            relationship_type: 'one_to_one',
            parent_association: include(type: 'has_one', name: 'profile')
          }
        end
      end
    end

    context 'with has_and_belongs_to_many associations' do
      let(:reflection_name) { 'tags' }
      let(:reflection_class) { ActiveRecord::Reflection::HasAndBelongsToManyReflection }
      let(:reflection_attributes) do
        {
          name: :tags,
          macro: :has_and_belongs_to_many,
          # rubocop:disable RSpec/VerifiedDoubles -- Using generic mock objects
          klass: double('Tag', name: 'Tag', table_name: 'tags'),
          # rubocop:enable RSpec/VerifiedDoubles
          polymorphic?: false,
          through_reflection?: false,
          options: {},
          join_table: 'test_models_tags',
          foreign_key: 'test_model_id',
          association_foreign_key: 'tag_id',
          active_record_primary_key: 'id'
        }
      end

      it_behaves_like 'extracted relationships'

      it_behaves_like 'relationship with expected attributes' do
        let(:expected_attributes) do
          {
            relationship_type: 'many_to_many',
            parent_association: include(type: 'has_and_belongs_to_many', name: 'tags')
          }
        end
      end
    end

    describe 'ActiveStorage' do
      let(:active_storage_attributes) do
        {
          # rubocop:disable RSpec/VerifiedDoubles -- Using generic mock objects
          klass: double('ActiveStorage::Attachment', name: 'ActiveStorage::Attachment',
            table_name: 'active_storage_attachments'),
          # rubocop:enable RSpec/VerifiedDoubles
          polymorphic?: false,
          through_reflection?: false,
          options: {},
          foreign_key: 'record_id',
          active_record_primary_key: 'id'
        }
      end

      context 'with has_many_attached associations' do
        let(:reflection_name) { 'images' }
        let(:reflection_class) { ActiveRecord::Reflection::HasManyReflection }
        let(:reflection_attributes) do
          active_storage_attributes.merge(
            name: :images,
            macro: :has_many_attached
          )
        end

        it_behaves_like 'extracted relationships'

        it_behaves_like 'relationship with expected attributes' do
          let(:expected_attributes) do
            {
              parent_table: 'test_models',
              child_table: 'active_storage_attachments',
              relationship_type: 'one_to_many',
              parent_association: include(type: 'has_many_attached', name: 'images')
            }
          end
        end
      end

      context 'with has_one_attached associations' do
        let(:reflection_name) { 'avatar' }
        let(:reflection_class) { ActiveRecord::Reflection::HasOneReflection }
        let(:reflection_attributes) do
          active_storage_attributes.merge(
            name: :avatar,
            macro: :has_one_attached
          )
        end

        it_behaves_like 'extracted relationships'

        it_behaves_like 'relationship with expected attributes' do
          let(:expected_attributes) do
            {
              parent_table: 'test_models',
              child_table: 'active_storage_attachments',
              relationship_type: 'one_to_one',
              parent_association: include(type: 'has_one_attached', name: 'avatar')
            }
          end
        end
      end
    end

    context 'with polymorphic belongs_to associations' do
      let(:reflection_name) { 'commentable' }
      let(:reflection_class) { ActiveRecord::Reflection::BelongsToReflection }
      let(:reflection_attributes) do
        {
          name: :commentable,
          macro: :belongs_to,
          klass: nil,
          polymorphic?: true,
          through_reflection?: false,
          options: { polymorphic: true },
          foreign_key: 'commentable_id',
          foreign_type: 'commentable_type'
        }
      end

      it_behaves_like 'extracted relationships'

      it_behaves_like 'relationship with expected attributes' do
        let(:expected_attributes) do
          {
            polymorphic?: true,
            child_association: include(type: 'belongs_to', name: 'commentable')
          }
        end
      end
    end

    context 'with polymorphic has_many associations' do
      let(:reflection_name) { 'comments' }
      let(:reflection_class) { ActiveRecord::Reflection::HasManyReflection }
      let(:reflection_attributes) do
        {
          name: :comments,
          macro: :has_many,
          # rubocop:disable RSpec/VerifiedDoubles -- Using generic mock objects
          klass: double('Comment', name: 'Comment', table_name: 'comments'),
          # rubocop:enable RSpec/VerifiedDoubles
          polymorphic?: true,
          through_reflection?: false,
          options: { as: :commentable },
          active_record_primary_key: 'id'
        }
      end

      it_behaves_like 'extracted relationships'

      it 'converts polymorphic has_many associations to relationships' do
        polymorphic_has_many = relationships.select do |r|
          r.parent_association&.dig(:name) == 'comments' && r.polymorphic?
        end

        expect(polymorphic_has_many).not_to be_empty
        polymorphic_has_many.each do |relationship|
          expect(relationship.polymorphic?).to be true
          expect(relationship.parent_association[:type]).to eq('has_many')
        end
      end
    end

    context 'with through associations' do
      let(:test_reflections) { { 'followers' => through_reflection } }

      let(:through_reflection) do # -- Using generic mock objects for ActiveRecord reflections
        instance_double(
          ActiveRecord::Reflection::ThroughReflection,
          name: :followers,
          macro: :has_many,
          # rubocop:disable RSpec/VerifiedDoubles -- Using generic mock objects
          klass: double('User', name: 'User', table_name: 'users'),
          # rubocop:enable RSpec/VerifiedDoubles
          polymorphic?: false,
          through_reflection?: true,
          options: { through: :follows },
          active_record_primary_key: 'id',
          through_reflection: through_belongs_to_reflection,
          source_reflection: source_belongs_to_reflection
        )
      end

      let(:through_belongs_to_reflection) do # -- Using generic mock objects for ActiveRecord reflections
        instance_double(
          ActiveRecord::Reflection::BelongsToReflection,
          macro: :belongs_to,
          foreign_key: 'follow_id',
          join_table: nil,
          table_name: 'follows'
        )
      end

      let(:source_belongs_to_reflection) do # -- Using generic mock objects for ActiveRecord reflections
        instance_double(
          ActiveRecord::Reflection::BelongsToReflection,
          foreign_key: 'follower_id'
        )
      end

      it_behaves_like 'extracted relationships'

      it_behaves_like 'relationship with expected attributes' do
        let(:expected_attributes) do
          {
            is_through_association: true,
            parent_association: include(name: 'followers')
          }
        end
      end
    end

    context 'with unsupported association types' do
      let(:reflection_name) { 'unsupported' }
      let(:reflection_class) { ActiveRecord::Reflection::AssociationReflection }
      let(:reflection_attributes) do
        {
          macro: :unsupported_type,
          polymorphic?: false,
          through_reflection?: false,
          options: {}
        }
      end

      it 'skips unsupported association types' do
        # Should not include relationships for unsupported association types
        unsupported_relationships = relationships.select do |r|
          r.parent_association&.dig(:name) == 'unsupported' ||
            r.child_association&.dig(:name) == 'unsupported'
        end

        expect(unsupported_relationships).to be_empty
      end
    end

    context 'with models containing no associations' do
      let(:mock_models) { [simple_model_class] }

      let(:simple_model_class) do
        # rubocop:disable RSpec/VerifiedDoubles -- Using generic mock objects
        double(
          'SimpleModel',
          name: 'SimpleModel',
          table_name: 'simple_models',
          reflections: {}
        )
        # rubocop:enable RSpec/VerifiedDoubles
      end

      it 'returns an empty array' do
        relationships = extractor.extract
        expect(relationships).to be_empty
      end
    end

    context 'when determine_handler_class returns nil' do
      let(:reflection_name) { 'polymorphic_without_as' }
      let(:reflection_class) { ActiveRecord::Reflection::HasManyReflection }
      let(:reflection_attributes) do
        {
          name: :polymorphic_without_as,
          macro: :has_many,
          # rubocop:disable RSpec/VerifiedDoubles -- Using generic mock objects
          klass: double('Comment', name: 'Comment', table_name: 'comments'),
          # rubocop:enable RSpec/VerifiedDoubles
          polymorphic?: true,
          through_reflection?: false,
          options: {} # Missing :as option
        }
      end

      it 'skips the association when handler_class is nil' do
        # Polymorphic has_many/has_one without :as option returns nil handler
        polymorphic_relationships = relationships.select do |r|
          r.parent_association&.dig(:name) == 'polymorphic_without_as'
        end

        expect(polymorphic_relationships).to be_empty
      end
    end
  end

  describe '#determine_handler_class' do
    context 'with unsupported macro in non-polymorphic reflection' do
      it 'raises an ArgumentError for unsupported macro types' do
        # Create a reflection with a macro that doesn't match any case statement branch
        reflection = instance_double(
          ActiveRecord::Reflection::AssociationReflection,
          macro: :unsupported_macro,
          polymorphic?: false
        )

        expect do
          extractor.send(:determine_handler_class, reflection)
        end.to raise_error(ArgumentError, /Unsupported reflection macro: unsupported_macro/)
      end
    end
  end
end
