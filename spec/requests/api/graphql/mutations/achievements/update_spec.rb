# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Achievements::Update, feature_category: :user_profile do
  include GraphqlHelpers
  include WorkhorseHelpers

  let_it_be(:developer) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:group) { create(:group, developers: developer, maintainers: maintainer) }

  let!(:achievement) { create(:achievement, namespace: group) }
  let(:mutation) { graphql_mutation(:achievements_update, params) }
  let(:achievement_id) { achievement&.to_global_id }
  let(:params) { { achievement_id: achievement_id, name: 'GitLab', avatar: avatar } }
  let(:avatar) { nil }

  subject { post_graphql_mutation_with_uploads(mutation, current_user: current_user) }

  def mutation_response
    graphql_mutation_response(:achievements_update)
  end

  context 'when the user does not have permission' do
    let(:current_user) { developer }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not update the achievement' do
      expect { subject }.not_to change { achievement.reload.name }
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

      it 'returns the relevant permission error' do
        subject

        expect(graphql_errors.to_s)
          .to include("The resource that you are attempting to access does not exist or you don't have permission")
      end
    end

    context 'with a new avatar' do
      let(:avatar) { fixture_file_upload("spec/fixtures/dk.png") }

      it 'updates the achievement' do
        subject

        achievement.reload

        expect(achievement.name).to eq('GitLab')
        expect(achievement.avatar.file).not_to be_nil
      end
    end
  end
end
