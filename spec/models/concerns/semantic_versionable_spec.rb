# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SemanticVersionable, feature_category: :mlops do
  using RSpec::Parameterized::TableSyntax

  let(:model_class) do
    Class.new(ActiveRecord::Base) do
      include SemanticVersionable
      semver_method :semver

      # we need a table for the dummy class to operate
      self.table_name = 'ml_model_versions'

      def self.name
        'Ml::ModelVersion'
      end

      attr_accessor :major, :minor, :patch, :prerelease
    end
  end

  describe '.semver_method' do
    describe 'setter method' do
      let(:model_instance) { model_class.new(semver: semver) }

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
    end

    describe 'getter method' do
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
    end
  end

  describe '.validate_semver' do
    it 'sets require_valid_semver to true' do
      model_class.validate_semver
      expect(model_class.require_valid_semver).to be true
    end

    it 'defaults to false' do
      expect(model_class.require_valid_semver).to be false
    end
  end

  describe 'semver validation' do
    let(:model_instance) { model_class.new }

    it 'validates when a valid semver is supplied' do
      model_class.validate_semver
      model_instance.semver = '1.2.3'
      expect(model_instance.valid?).to be true
    end

    it 'fails validation when an invalid version is supplied' do
      model_class.validate_semver
      model_instance.semver = '123'
      expect(model_instance.valid?).to be false
      expect(model_instance.errors.count).to be(1)
      expect(model_instance.errors.first.attribute).to eq(:base)
      expect(model_instance.errors.first.message).to eq('must follow semantic version')
    end

    it 'does not validate if the validation is not enabled' do
      model_instance.semver = '123'
      expect(model_instance.valid?).to be true
    end
  end
end
