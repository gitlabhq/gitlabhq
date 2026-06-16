# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RestApi::EntityUsageRadiusAnalyzer, feature_category: :api do
  describe '#high_impact_entities' do
    subject(:high_impact) { described_class.new.high_impact_entities }

    it 'returns a hash mapping entity classes to usage radius counts' do
      expect(high_impact).to be_a(Hash)
      expect(high_impact).not_to be_empty

      high_impact.each do |entity_class, usage_radius|
        expect(entity_class).to be < Grape::Entity
        expect(usage_radius).to be_a(Integer)
        expect(usage_radius).to be >= described_class::THRESHOLD
      end
    end

    it 'confirms the live entity graph contains at least one known high-impact entity' do
      entity_names = high_impact.keys.map(&:name)

      expect(entity_names).to include('API::Entities::UserBasic')
    end
  end

  describe 'BFS cycle handling' do
    it 'returns a finite usage radius when reverse dependencies form a cycle' do
      analyzer = described_class.new
      entity_a = Class.new(Grape::Entity)
      entity_b = Class.new(Grape::Entity)

      analyzer.instance_variable_set(:@direct_endpoint_counts, { entity_a => 5, entity_b => 3 })
      deps = Hash.new { |h, k| h[k] = Set.new }
      deps[entity_a] << entity_b
      deps[entity_b] << entity_a
      analyzer.instance_variable_set(:@reverse_dependencies, deps)

      radius = analyzer.send(:usage_radius_for, entity_a)

      expect(radius).to eq(8)
    end
  end

  describe '.entity_file_path' do
    it 'returns the relative path for a known entity class' do
      path = described_class.entity_file_path(API::Entities::UserSafe)

      expect(path).to eq('lib/api/entities/user_safe.rb')
    end

    it 'returns nil for classes without a source location' do
      anonymous_class = Class.new(Grape::Entity)

      path = described_class.entity_file_path(anonymous_class)

      expect(path).to be_nil
    end
  end

  describe '.extract_field_names' do
    it 'extracts expose field names from entity files' do
      fields = described_class.extract_field_names('lib/api/entities/user_safe.rb')

      expect(fields).to include('id', 'name', 'username')
    end

    it 'returns empty array for non-existent files' do
      fields = described_class.extract_field_names('lib/api/entities/nonexistent.rb')

      expect(fields).to be_empty
    end

    it 'collects all symbol arguments from multi-arg expose calls' do
      content = <<~RUBY
        # frozen_string_literal: true

        class FakeEntity < Grape::Entity
          expose :id, :name, :email
          expose :avatar_url
        end
      RUBY

      with_temp_entity_file(content) do |relative_path|
        fields = described_class.extract_field_names(relative_path)

        expect(fields).to contain_exactly('id', 'name', 'email', 'avatar_url')
      end
    end
  end

  describe '.extract_entity_classes' do
    let(:entity_class) { Class.new(Grape::Entity) }

    it 'returns array with single class when given a Class' do
      expect(described_class.extract_entity_classes(entity_class)).to eq([entity_class])
    end

    it 'returns classes from Hash with :model key' do
      expect(described_class.extract_entity_classes({ model: entity_class })).to eq([entity_class])
    end

    it 'returns classes from Hash with :entity key' do
      expect(described_class.extract_entity_classes({ entity: entity_class })).to eq([entity_class])
    end

    it 'returns classes from Array form' do
      expect(described_class.extract_entity_classes([entity_class])).to eq([entity_class])
    end

    it 'recurses into nested arrays' do
      expect(described_class.extract_entity_classes([[entity_class]])).to eq([entity_class])
    end

    it 'returns empty array for non-class values' do
      expect(described_class.extract_entity_classes('not a class')).to be_empty
      expect(described_class.extract_entity_classes(nil)).to be_empty
      expect(described_class.extract_entity_classes({})).to be_empty
    end
  end

  describe '.collect_using_classes' do
    let(:represent_class) { Grape::Entity::Exposure::RepresentExposure }
    let(:nesting_class) { Grape::Entity::Exposure::NestingExposure }

    it 'returns empty array for empty exposures' do
      expect(described_class.collect_using_classes([])).to be_empty
    end

    it 'collects using_class from a flat list of exposures' do
      using_class = Class.new(Grape::Entity)
      exposure = instance_double(represent_class, using_class: using_class)

      result = described_class.collect_using_classes([exposure])

      expect(result).to contain_exactly(using_class)
    end

    it 'recurses into nested exposures' do
      inner_class = Class.new(Grape::Entity)
      outer_class = Class.new(Grape::Entity)
      inner_exposure = instance_double(represent_class, using_class: inner_class)
      inner_nesting = instance_double(nesting_class, nested_exposures: [inner_exposure])
      outer_exposure = instance_double(represent_class, using_class: outer_class)
      outer_nesting = instance_double(nesting_class, nested_exposures: [outer_exposure, inner_nesting])

      result = described_class.collect_using_classes([outer_nesting])

      expect(result).to contain_exactly(outer_class, inner_class)
    end

    it 'handles exposures without using_class (e.g. NestingExposure)' do
      inner_class = Class.new(Grape::Entity)
      represent_exposure = instance_double(represent_class, using_class: inner_class)
      nesting_exposure = instance_double(nesting_class, nested_exposures: [represent_exposure])

      result = described_class.collect_using_classes([nesting_exposure])

      expect(result).to contain_exactly(inner_class)
    end
  end

  def with_temp_entity_file(content)
    require 'tempfile'

    tmp_dir = Rails.root.join('tmp')
    FileUtils.mkdir_p(tmp_dir)

    file = Tempfile.new(['fake_entity', '.rb'], tmp_dir)
    file.write(content)
    file.flush

    relative = Pathname.new(file.path).relative_path_from(Rails.root).to_s
    yield relative
  ensure
    file&.close
    file&.unlink
  end
end
