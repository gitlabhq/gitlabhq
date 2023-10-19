# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/background_migration/feature_category'

RSpec.describe RuboCop::Cop::BackgroundMigration::FeatureCategory, feature_category: :database do
  context 'for non background migrations' do
    before do
      allow(cop).to receive(:in_background_migration?).and_return(false)
    end

    it 'does not throw any offense' do
      expect_no_offenses(<<~RUBY)
        module Gitlab
          module BackgroundMigration
            class MyJob < Gitlab::BackgroundMigration::BatchedMigrationJob
              def perform; end
            end
          end
        end
      RUBY
    end
  end

  context 'for background migrations' do
    before do
      allow(cop).to receive(:in_background_migration?).and_return(true)
    end

    it 'throws offense on not defining the feature_category' do
      expect_offense(<<~RUBY)
        module Gitlab
          module BackgroundMigration
            class MyJob1 < Gitlab::BackgroundMigration::BatchedMigrationJob
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG}
            end
          end
        end
      RUBY
    end

    it 'throws offense on not defining a valid feature_category' do
      expect_offense(<<~RUBY)
        module Gitlab
          module BackgroundMigration
            class MyJob1 < Gitlab::BackgroundMigration::BatchedMigrationJob
            feature_category :invalid_random
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::INVALID_FEATURE_CATEGORY_MSG}
            end
          end
        end
      RUBY
    end

    it 'will not throw offense on defining a valid feature_category' do
      expect_no_offenses(<<~RUBY)
        module Gitlab
          module BackgroundMigration
            class MyJob < Gitlab::BackgroundMigration::BatchedMigrationJob
              feature_category :database

              def perform; end
            end
          end
        end
      RUBY
    end
  end

  describe '#external_dependency_checksum' do
    it 'returns a SHA256 digest used by RuboCop to invalid cache' do
      expect(cop.external_dependency_checksum).to match(/^\h{64}$/)
    end
  end
end
