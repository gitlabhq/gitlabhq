# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Organizations::IsolationStatus, feature_category: :organization do
  describe '#verify!' do
    let_it_be_with_reload(:issue) { create(:issue) }
    let_it_be(:other_organization) { create(:organization, path: 'other-org') }
    let_it_be(:other_user) { create(:user, organization: other_organization) }
    let_it_be(:other_namespace) { create(:namespace, owner: other_user, organization: other_organization) }
    let_it_be(:other_project) { create(:project, creator: other_user, namespace: other_namespace) }
    let(:changed_attributes) { [:duplicated_to] }
    let(:related_issue) { build(:issue) }

    subject(:verify) { described_class.new(issue, changed_attributes).verify! }

    before do
      issue.organization.mark_as_isolated!
    end

    context 'when the related object has a different organization' do
      let!(:related_issue) { create(:issue, project: other_project) }

      it 'marks the organization and namespace as not isolated' do
        expect(Gitlab::AppLogger).to receive(:info).with(message: 'Isolation status set to false',
          organization_path: issue.organization.path)

        issue.update!(duplicated_to: related_issue)

        expect { verify }
          .to change { issue.organization.reload.isolated? }.from(true).to(false)
      end
    end

    shared_examples 'does not change isolation status' do
      it 'does not change the isolation status' do
        issue.update!(duplicated_to: related_issue)

        expect { verify }
          .to not_change { issue.organization.isolated? }
      end
    end

    context 'when the related object is in the same organization' do
      it_behaves_like "does not change isolation status"
    end

    context 'when the organization is marked as not isolated' do
      before do
        issue.organization.mark_as_not_isolated!
      end

      it_behaves_like "does not change isolation status"
    end

    context 'when the related object is nil' do
      before do
        issue.update_column(:duplicated_to_id, nil)
      end

      it 'does not change the isolation status' do
        expect { verify }
          .to not_change { issue.organization.isolated? }
      end
    end

    context 'when the related object organization cannot be determined' do
      let!(:related_issue) { create(:issue) }

      before do
        issue.update!(duplicated_to: related_issue)
        allow(related_issue).to receive(:organization).and_return(nil)
      end

      it 'does not change the isolation status' do
        expect { verify }
          .to not_change { issue.organization.isolated? }
      end
    end
  end
end
