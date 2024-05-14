# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Achievements::Delete, feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:developer) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:group) { create(:group, developers: developer, maintainers: maintainer) }

  let!(:achievement) { create(:achievement, namespace: group) }
  let(:mutation) { graphql_mutation(:achievements_delete, params) }
  let(:achievement_id) { achievement&.to_global_id }
  let(:params) { { achievement_id: achievement_id } }

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  def mutation_response
    graphql_mutation_response(:achievements_delete)
  end

  context 'when the user does not have permission' do
    let(:current_user) { developer }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not revoke any achievements' do
      expect { subject }.not_to change { Achievements::Achievement.count }
    end
  end

  context 'when the user has permission' do
    let(:current_user) { maintainer }

    context 'when the params are invalid' do
      let(:achievement) { nil }

      it 'returns the validation error' do
        subject

        expect(graphql_errors.to_s).to include('invalid value for achievementId (Expected value to not be null)')
      end
    end

    context 'when the achievement_id is invalid' do
      let(:achievement_id) { "gid://gitlab/Achievements::Achievement/#{non_existing_record_id}" }

      it 'returns the validation error' do
        subject

        expect(graphql_errors.to_s)
          .to include("The resource that you are attempting to access does not exist or you don't have permission")
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(achievements: false)
      end

      it 'returns the relevant error' do
        subject

        expect(graphql_errors.to_s)
          .to include("The resource that you are attempting to access does not exist or you don't have permission")
      end
    end

    it 'deletes the achievement' do
      expect { subject }.to change { Achievements::Achievement.count }.by(-1)
    end
  end
end
