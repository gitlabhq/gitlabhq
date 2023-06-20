# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::Projects::CreatorService, feature_category: :groups_and_projects do
  let_it_be(:source, reload: true) { create(:project, :public) }
  let_it_be(:source2, reload: true) { create(:project, :public) }
  let_it_be(:user) { create(:user) }

  describe '.access_levels' do
    it 'returns Gitlab::Access.sym_options_with_owner' do
      expect(described_class.access_levels).to eq(Gitlab::Access.sym_options_with_owner)
    end
  end

  it_behaves_like 'owner management'

  describe '.add_members' do
    it_behaves_like 'bulk member creation' do
      let_it_be(:source_type) { Project }
      let_it_be(:member_type) { ProjectMember }
    end
  end

  describe '.add_member' do
    it_behaves_like 'member creation' do
      let_it_be(:member_type) { ProjectMember }
    end

    context 'authorized projects update' do
      it 'schedules a single project authorization update job when called multiple times' do
        stub_feature_flags(do_not_run_safety_net_auth_refresh_jobs: false)

        expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker).to receive(:bulk_perform_in).once

        1.upto(3) do
          described_class.add_member(source, user, :maintainer)
        end
      end
    end
  end
end
