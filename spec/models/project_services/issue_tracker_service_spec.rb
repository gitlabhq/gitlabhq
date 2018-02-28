require 'spec_helper'

describe IssueTrackerService do
  describe 'Validations' do
    let(:project) { create :project }

    describe 'only one issue tracker per project' do
      let(:service) { RedmineService.new(project: project, active: true) }

      before do
        create(:custom_issue_tracker_service, project: project)
      end

      context 'when service is changed manually by user' do
        it 'executes the validation' do
          valid = service.valid?(:manual_change)

          expect(valid).to be_falsey
          expect(service.errors[:base]).to include(
            'Another issue tracker is already in use. Only one issue tracker service can be active at a time'
          )
        end
      end

      context 'when service is changed internally' do
        it 'does not execute the validation' do
          expect(service.valid?).to be_truthy
        end
      end
    end
  end
end
