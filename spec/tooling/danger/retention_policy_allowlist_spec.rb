# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/retention_policy_allowlist'

RSpec.describe Tooling::Danger::RetentionPolicyAllowlist, feature_category: :database do
  include_context 'with dangerfile'

  subject(:retention_policy_allowlist) { fake_danger.new(helper: fake_helper) }

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:allowlist_path) { described_class::ALLOWLIST_PATH }
  let(:changed_files) { [allowlist_path] }
  let(:changed_lines) { [] }

  before do
    allow(fake_helper).to receive(:all_changed_files).and_return(changed_files)
    allow(fake_helper).to receive(:changed_lines).with(allowlist_path).and_return(changed_lines)
  end

  describe '#check_retention_policy_allowlist_additions' do
    context 'when the allowlist file was not changed' do
      let(:changed_files) { ['app/models/user.rb'] }

      it 'does not fail' do
        expect(retention_policy_allowlist).not_to receive(:fail)

        retention_policy_allowlist.check_retention_policy_allowlist_additions
      end
    end

    context 'when the allowlist only had entries removed' do
      let(:changed_lines) do
        [
          '-- abuse_report_uploads'
        ]
      end

      it 'does not fail' do
        expect(retention_policy_allowlist).not_to receive(:fail)

        retention_policy_allowlist.check_retention_policy_allowlist_additions
      end
    end

    context 'when new entries are added to the allowlist' do
      let(:changed_lines) do
        [
          '+- brand_new_table',
          '+- another_new_table'
        ]
      end

      it 'fails with a message naming every added table and the allowlist path' do
        expect(retention_policy_allowlist).to receive(:fail) do |message|
          expect(message).to include('brand_new_table')
          expect(message).to include('another_new_table')
          expect(message).to include(allowlist_path)
        end

        retention_policy_allowlist.check_retention_policy_allowlist_additions
      end
    end

    context 'when there are no changed lines for the allowlist' do
      let(:changed_lines) { [] }

      it 'does not fail' do
        expect(retention_policy_allowlist).not_to receive(:fail)

        retention_policy_allowlist.check_retention_policy_allowlist_additions
      end
    end

    context 'when an added entry has a trailing YAML comment' do
      let(:changed_lines) do
        [
          '+- brand_new_table # TODO: remove'
        ]
      end

      it 'reports the table name without the comment' do
        expect(retention_policy_allowlist).to receive(:fail) do |message|
          expect(message).to include('`brand_new_table`')
          expect(message).not_to include('TODO')
        end

        retention_policy_allowlist.check_retention_policy_allowlist_additions
      end
    end

    context 'when an added entry is wrapped in double quotes' do
      let(:changed_lines) do
        [
          '+- "brand_new_table"'
        ]
      end

      it 'reports the table name without the quotes' do
        expect(retention_policy_allowlist).to receive(:fail) do |message|
          expect(message).to include('`brand_new_table`')
          expect(message).not_to include('"brand_new_table"')
        end

        retention_policy_allowlist.check_retention_policy_allowlist_additions
      end
    end

    context 'when an added entry is wrapped in single quotes' do
      let(:changed_lines) do
        [
          "+- 'brand_new_table'"
        ]
      end

      it 'reports the table name without the quotes' do
        expect(retention_policy_allowlist).to receive(:fail) do |message|
          expect(message).to include('`brand_new_table`')
          expect(message).not_to include("'brand_new_table'")
        end

        retention_policy_allowlist.check_retention_policy_allowlist_additions
      end
    end
  end
end
