# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::BaseIssueTracker do
  describe 'Validations' do
    let(:project) { create :project }

    describe 'only one issue tracker per project' do
      let(:integration) { Integrations::Redmine.new(project: project, active: true, issue_tracker_data: build(:issue_tracker_data)) }

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
end
