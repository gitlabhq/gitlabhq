# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SemanticVersionable, feature_category: :mlops do
  using RSpec::Parameterized::TableSyntax

  before do
    model_class.reset_column_information
  end

  before_all do
    ActiveRecord::Schema.define do |_t|
      create_table :_test_semantic_versions, force: true do |t|
        t.integer :semver_major
        t.integer :semver_minor
        t.integer :semver_patch
        t.string :semver_prerelease
      end
    end
  end

  let(:model_class) do
    Class.new(ActiveRecord::Base) do
      include SemanticVersionable

      self.table_name = '_test_semantic_versions'
    end
  end

  let(:model_instance) { model_class.new(semver: semver) }

  describe '#semver=' do
    where(:semver, :major, :minor, :patch, :prerelease) do
      '1'             | nil | nil | nil | nil
      '1.2'           | nil | nil | nil | nil
      '1.2.3'         | 1   | 2   | 3   | nil
      '1.2.3-beta'    | 1   | 2   | 3   | 'beta'
      '1.2.3.beta'    | nil | nil | nil | nil
    end

    with_them do
      it do
        expect(model_instance.semver_major).to be major
        expect(model_instance.semver_minor).to be minor
        expect(model_instance.semver_patch).to be patch
        expect(model_instance.semver_prerelease).to eq prerelease
      end
    end

    context 'with a prefix' do
      before do
        ActiveRecord::Schema.define do
          add_column :_test_semantic_versions, :semver_prefixed, :boolean
        end
      end

      where(:semver, :major, :minor, :patch, :prerelease, :prefixed) do
        'v1.2.3'         | 1 | 2 | 3 | nil    | true
        'v1.2.3-beta'    | 1 | 2 | 3 | 'beta' | true
      end

      with_them do
        it do
          expect(model_instance.semver_major).to be major
          expect(model_instance.semver_minor).to be minor
          expect(model_instance.semver_patch).to be patch
          expect(model_instance.semver_prerelease).to eq prerelease
          expect(model_instance.semver_prefixed).to eq prefixed
        end
      end
    end
  end

  describe '#semver' do
    let(:model_instance) { model_class.new(semver: semver_input) }

    where(:semver_input, :semver_value) do
      '1'             | ''
      '1.2'           | ''
      '1.2.3'         | '1.2.3'
      '1.2.3-beta'    | '1.2.3-beta'
      '1.2.3.beta'    | ''
    end

    with_them do
      it do
        expect(model_instance.semver.to_s).to eq semver_value
      end
    end

    context 'with a prefix' do
      before do
        ActiveRecord::Schema.define do
          add_column :_test_semantic_versions, :semver_prefixed, :boolean
        end
      end

      where(:semver_input, :semver_value) do
        'v1.2.3'         | 'v1.2.3'
        'v1.2.3-beta'    | 'v1.2.3-beta'
      end

      with_them do
        it do
          expect(model_instance.semver.to_s).to eq semver_value
        end
      end
    end
  end

  describe 'scopes' do
    let(:first_release) { model_class.create!(semver: '1.0.1') }
    let(:second_release) { model_class.create!(semver: '3.0.1') }
    let(:patch) { model_class.create!(semver: 'v2.0.1') }

    describe '.order_by_semantic_version_asc' do
      it 'orders the versions by semantic order ascending' do
        expect(model_class.order_by_semantic_version_asc).to eq([first_release, patch, second_release])
      end
    end

    describe '.order_by_semantic_version_desc' do
      it 'orders the versions by semantic order descending' do
        expect(model_class.order_by_semantic_version_desc).to eq([second_release, patch, first_release])
      end
    end
  end
end
