# frozen_string_literal: true

require 'spec_helper'
RSpec.describe Terraform::States::RestoreService, feature_category: :infrastructure_as_code do
  let_it_be(:project) { create(:project) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let(:current_user) { maintainer }
  let(:deleted_at) { Time.current }
  let(:state) { create(:terraform_state, project: project, deleted_at: deleted_at) }

  subject(:response) { described_class.new(state, current_user: current_user).execute }

  before_all do
    project.add_maintainer(maintainer)
    project.add_developer(developer)
  end

  around do |example|
    freeze_time { example.run }
  end

  context 'when the user can administer Terraform state' do
    it 'restores a state within the grace period' do
      expect(response).to be_success
      expect(response.payload).to eq(terraform_state: state)
      expect(state.reload.deleted_at).to be_nil
    end
  end

  context 'when the user cannot administer Terraform state' do
    let(:current_user) { developer }

    it 'returns an error and leaves the state deleted' do
      expect(response).to be_error
      expect(response.errors).to contain_exactly(
        'You have insufficient permissions to restore this state'
      )
      expect(state.reload.deleted_at).to eq(deleted_at)
    end
  end

  context 'when the state is not marked for deletion' do
    let(:deleted_at) { nil }

    it 'returns an error' do
      expect(response).to be_error
      expect(response.errors).to contain_exactly('State is not marked for deletion')
    end
  end

  context 'when the grace period has elapsed' do
    let(:deleted_at) { Terraform::State::GRACE_PERIOD.ago }

    it 'returns an error and leaves the state deleted' do
      expect(response).to be_error
      expect(response.errors).to contain_exactly('Grace period for this state has elapsed')
      expect(state.reload.deleted_at).to eq(deleted_at)
    end
  end

  context 'when one second remains in the grace period' do
    let(:deleted_at) { Terraform::State::GRACE_PERIOD.ago + 1.second }

    it 'restores the state' do
      expect(response).to be_success
      expect(state.reload.deleted_at).to be_nil
    end
  end
end
