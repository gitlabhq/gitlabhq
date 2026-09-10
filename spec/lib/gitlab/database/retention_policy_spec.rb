# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::RetentionPolicy, feature_category: :database do
  def policy_for(fixture_name)
    described_class.from_file(expand_fixture_path("lib/gitlab/database/retention_policy/#{fixture_name}.yml"))
  end

  describe 'allowlist and exclusion constants' do
    it 'only allows each schema in one constant' do
      common_schemas = described_class::ELIGIBLE_SCHEMAS.intersection(described_class::EXCLUDED_SCHEMAS)

      expect(common_schemas).to be_empty, <<~MSG
        Schema(s) #{common_schemas.join(', ')} should either be excluded or allowed.
      MSG
    end
  end

  describe '.eligible_tables' do
    it 'contains only eligible schemas' do
      schemas = described_class.eligible_tables.map(&:gitlab_schema).uniq

      expect(schemas).to match_array(described_class::ELIGIBLE_SCHEMAS)
      expect(schemas).not_to include(*described_class::EXCLUDED_SCHEMAS)
    end
  end

  describe '.from_file' do
    it 'uses the file basename as the table name' do
      policy = policy_for('valid_enforced')

      expect(policy.table_name).to eq('valid_enforced')
    end

    it 'loads the YAML contents into data' do
      policy = policy_for('valid_enforced')

      expect(policy.data).to include('retention_window' => 90, 'enforcement_strategy' => 'delete_rows')
    end
  end

  describe '#initialize' do
    it 'defaults data to an empty hash when nil is passed' do
      policy = described_class.new('some_table', nil)

      expect(policy.data).to eq({})
    end
  end

  describe '#excluded?' do
    it 'is true when exclude is a populated hash' do
      expect(policy_for('valid_excluded')).to be_excluded
    end

    it 'is true when exclude is a non-Hash truthy value' do
      expect(policy_for('invalid_non_hash_exclude')).to be_excluded
    end

    it 'is false when exclude is absent' do
      expect(policy_for('valid_enforced')).not_to be_excluded
    end
  end

  describe '#exclude_reason' do
    it 'returns the reason when exclude is a hash with a reason' do
      expect(policy_for('valid_excluded').exclude_reason).to eq('indefinite_retention')
    end

    it 'returns nil when exclude is a non-Hash value, without raising' do
      policy = policy_for('invalid_non_hash_exclude')

      expect { policy.exclude_reason }.not_to raise_error
      expect(policy.exclude_reason).to be_nil
    end

    it 'returns nil when exclude is absent' do
      expect(policy_for('valid_enforced').exclude_reason).to be_nil
    end
  end

  describe '#pause_mechanism' do
    it 'returns the type field from the pause_mechanism hash' do
      expect(policy_for('valid_enforced').pause_mechanism).to eq('application_setting')
    end

    it 'returns nil when pause_mechanism is not a hash' do
      policy = described_class.new('t', 'pause_mechanism' => 'application_setting')

      expect(policy.pause_mechanism).to be_nil
    end
  end

  describe '#pause_mechanism_name' do
    it 'returns the name field from the pause_mechanism hash' do
      expect(policy_for('valid_enforced').pause_mechanism_name).to eq('example_retention_enabled')
    end

    it 'returns nil when pause_mechanism is not a hash' do
      policy = described_class.new('t', 'pause_mechanism' => 'application_setting')

      expect(policy.pause_mechanism_name).to be_nil
    end
  end

  describe '#validation_errors' do
    context 'with valid declarations' do
      it 'accepts an enforced policy' do
        expect(policy_for('valid_enforced').validation_errors).to be_empty
      end

      it 'accepts an excluded policy with placeholder window and strategy' do
        expect(policy_for('valid_excluded').validation_errors).to be_empty
      end
    end

    context 'with invalid declarations' do
      it 'rejects unknown fields' do
        expect(policy_for('invalid_disallowed_field').validation_errors)
          .to include(a_string_matching(/fields not allowed: unknown_field/))
      end

      it 'rejects missing required fields' do
        expect(policy_for('invalid_missing_fields').validation_errors)
          .to include(a_string_matching(/missing required fields/))
      end

      it 'rejects an unknown enforcement_strategy' do
        expect(policy_for('invalid_enforcement_strategy').validation_errors)
          .to include(a_string_matching(/enforcement_strategy must be one of/))
      end

      it 'rejects an unknown exclude reason' do
        expect(policy_for('invalid_exclude_reason').validation_errors)
          .to include(a_string_matching(/exclude.reason must be one of/))
      end

      it 'rejects placeholder window and strategy without an exclude reason' do
        expect(policy_for('invalid_coupling').validation_errors)
          .to include(a_string_matching(/only allowed when exclude.reason is set/))
      end

      it 'rejects an excluded declaration that does not use the placeholders' do
        expect(policy_for('invalid_excluded_without_placeholders').validation_errors)
          .to include(a_string_matching(/both required when exclude.reason is set/))
      end

      it 'rejects a non-none pause_mechanism without a name' do
        expect(policy_for('invalid_pause_mechanism_missing_name').validation_errors)
          .to include(a_string_matching(/pause_mechanism.name is required when pause_mechanism.type is feature_flag/))
      end

      it 'rejects a pause_mechanism that is not a hash' do
        expect(policy_for('invalid_pause_mechanism_not_hash').validation_errors)
          .to include(a_string_matching(/pause_mechanism must be a hash/))
      end

      it 'rejects a non-Hash exclude value without raising a TypeError' do
        policy = policy_for('invalid_non_hash_exclude')

        expect { policy.validation_errors }.not_to raise_error
        expect(policy.validation_errors)
          .to include(a_string_matching(/exclude.reason must be one of/))
      end

      it 'rejects a string retention_window' do
        expect(policy_for('invalid_retention_window_string').validation_errors)
          .to include(a_string_matching(/retention_window must be a positive number of days/))
      end

      it 'rejects a zero retention_window' do
        expect(policy_for('invalid_retention_window_zero').validation_errors)
          .to include(a_string_matching(/retention_window must be a positive number of days/))
      end

      it 'rejects a negative retention_window other than the excluded placeholder' do
        expect(policy_for('invalid_retention_window_negative').validation_errors)
          .to include(a_string_matching(/retention_window must be a positive number of days/))
      end

      it 'rejects a non-boolean enforcing' do
        expect(policy_for('invalid_enforcing_string').validation_errors)
          .to include(a_string_matching(/enforcing must be true or false/))
      end

      it 'rejects a declaration missing work_item' do
        expect(policy_for('invalid_missing_work_item').validation_errors)
          .to include(a_string_matching(/missing required fields.*work_item/))
      end

      it 'rejects an array YAML root without raising' do
        policy = policy_for('invalid_non_hash_root_array')

        expect { policy.validation_errors }.not_to raise_error
        expect(policy.validation_errors)
          .to include(a_string_matching(/missing required fields/))
      end

      it 'rejects a scalar YAML root without raising' do
        policy = policy_for('invalid_non_hash_root_scalar')

        expect { policy.validation_errors }.not_to raise_error
        expect(policy.validation_errors)
          .to include(a_string_matching(/missing required fields/))
      end
    end
  end
end
