# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureGroups::GitlabTeamMembers do # rubocop:disable RSpec/MissingFeatureCategory
  let_it_be(:gitlab_com) { create(:group) }
  let_it_be_with_reload(:member) { create(:user).tap { |user| gitlab_com.add_developer(user) } }
  let_it_be_with_reload(:non_member) { create(:user) }

  before do
    stub_const("#{described_class.name}::GITLAB_COM_GROUP_ID", gitlab_com.id)
  end

  describe '#enabled?' do
    context 'when not on gitlab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      it 'returns false' do
        expect(described_class.enabled?(member)).to eq(false)
      end
    end

    context 'when on gitlab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'returns true for gitlab-com group members' do
        expect(described_class.enabled?(member)).to eq(true)
      end

      it 'returns false for users not in gitlab-com' do
        expect(described_class.enabled?(non_member)).to eq(false)
      end

      it 'returns false when actor is not a user' do
        expect(described_class.enabled?(gitlab_com)).to eq(false)
      end

      it 'reloads members after 1 hour' do
        expect(described_class.enabled?(non_member)).to eq(false)

        gitlab_com.add_developer(non_member)

        travel_to(2.hours.from_now) do
          expect(described_class.enabled?(non_member)).to eq(true)
        end
      end

      it 'does not make queries on subsequent calls', :use_clean_rails_memory_store_caching do
        described_class.enabled?(member)
        non_member

        queries = ActiveRecord::QueryRecorder.new do
          described_class.enabled?(member)
          described_class.enabled?(non_member)
        end

        expect(queries.count).to eq(0)
      end
    end
  end
end
