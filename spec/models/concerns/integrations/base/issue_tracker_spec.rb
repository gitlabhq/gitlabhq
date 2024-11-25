# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Base::IssueTracker, feature_category: :integrations do
  let(:integration) do
    build(
      :redmine_integration,
      project: project,
      active: true,
      issue_tracker_data:
      build(:issue_tracker_data)
    )
  end

  let_it_be_with_refind(:project) { create(:project) }

  describe 'default values' do
    it { expect(integration.category).to eq(:issue_tracker) }
  end

  describe 'Validations' do
    describe 'only one issue tracker per project' do
      before do
        create(:custom_issue_tracker_integration, project: project)
      end

      context 'when integration is changed manually by user' do
        it 'executes the validation' do
          valid = integration.valid?(:manual_change)

          expect(valid).to be_falsey
          expect(integration.errors[:base]).to include(
            'Another issue tracker is already in use. Only one issue tracker service can be active at a time'
          )
        end
      end

      context 'when integration is changed internally' do
        it 'does not execute the validation' do
          expect(integration.valid?).to be_truthy
        end
      end
    end
  end

  describe '#activate_disabled_reason' do
    subject { integration.activate_disabled_reason }

    context 'when there is an existing issue tracker integration' do
      let_it_be(:custom_tracker) { create(:custom_issue_tracker_integration, project: project) }

      it { is_expected.to eq(trackers: [custom_tracker]) }
    end

    context 'when there is no existing issue tracker integration' do
      it { is_expected.to be_nil }
    end
  end
end
