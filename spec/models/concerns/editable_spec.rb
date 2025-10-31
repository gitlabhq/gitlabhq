# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Editable do
  describe '#edited?' do
    let(:issue) { create(:issue, last_edited_at: nil) }
    let(:edited_issue) { create(:issue, created_at: 3.days.ago, last_edited_at: 2.days.ago) }

    it { expect(issue.edited?).to eq(false) }
    it { expect(edited_issue.edited?).to eq(true) }
  end

  describe '#last_edited_by' do
    let(:organization) { create(:organization) }
    let(:author) { create(:user, organization: organization) }
    let(:edited_note) { create(:note, author: author, created_at: 3.days.ago, last_edited_at: 2.days.ago) }

    subject(:last_edited_by) { edited_note.last_edited_by }

    context 'when actual last_edited_by cannot be found' do
      context 'and organization_id is specified on editable' do
        let(:other_organization) { create(:organization) }
        let(:ghost_user) { Users::Internal.for_organization(other_organization).ghost }
        let(:edited_note) do
          create(:note, author: author, created_at: 3.days.ago, last_edited_at: 2.days.ago,
            organization: other_organization)
        end

        before do
          allow(edited_note).to receive(:updated_by).and_return(nil)
        end

        it { is_expected.to eq(ghost_user) }
      end

      context 'and editable does not have organization_id' do
        let_it_be(:first_org) { create(:organization) }
        let_it_be(:project_org) { create(:organization) }
        let_it_be(:creator) { create(:user, organization: project_org) }
        let_it_be(:project) { create(:project, creator: creator, organization: project_org) }
        let_it_be(:updated_by) { create(:user, organization: project_org) }
        let_it_be_with_refind(:editable) { create(:issue, project: project, updated_by: updated_by) }

        let(:ghost_user) { Users::Internal.for_organization(project.creator.organization).ghost }

        subject(:last_edited_by) { editable.last_edited_by }

        before do
          allow(editable).to receive_messages(edited?: true, updated_by: nil)
        end

        it { is_expected.to eq(ghost_user) }

        context 'and author is missing or deleted' do
          let(:ghost_organization) { create(:common_organization) }
          let(:ghost_user) { Users::Internal.for_organization(ghost_organization).ghost }

          before do
            allow(Organizations::Organization).to receive(:first).and_return(ghost_organization)
            allow(editable).to receive(:author).and_return(nil)
          end

          it 'returns ghost based on first available organization' do
            expect(ghost_organization).not_to eq(project.creator.organization)
            expect(Gitlab::AppLogger).to receive(:warn).with(/Fallback ghost user/)
            expect(last_edited_by).to eq(ghost_user)
          end
        end
      end
    end
  end
end
