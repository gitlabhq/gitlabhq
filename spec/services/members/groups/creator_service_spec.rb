# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::Groups::CreatorService do
  describe '.access_levels' do
    it 'returns Gitlab::Access.options_with_owner' do
      expect(described_class.access_levels).to eq(Gitlab::Access.sym_options_with_owner)
    end
  end

  describe '#execute' do
    let_it_be(:source, reload: true) { create(:group, :public) }
    let_it_be(:user) { create(:user) }

    it_behaves_like 'member creation' do
      let_it_be(:member_type) { GroupMember }
    end

    context 'authorized projects update' do
      it 'schedules a single project authorization update job when called multiple times' do
        expect(AuthorizedProjectsWorker).to receive(:bulk_perform_and_wait).once

        1.upto(3) do
          described_class.new(source, user, :maintainer).execute
        end
      end
    end
  end
end
