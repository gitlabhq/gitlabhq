# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::AutoRecoverWorker, feature_category: :continuous_delivery do
  include CreateEnvironmentsHelpers

  subject { worker.perform(environment_id) }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }

  let!(:environment) { create_review_app(user, project, 'review/feature').environment }
  let(:environment_id) { environment.id }
  let(:worker) { described_class.new }
  let(:user) { developer }

  before_all do
    project.repository.add_branch(developer, 'review/feature', 'master')
  end

  it 'has the `until_executed` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  context 'when environment has been updated recently' do
    it 'recovers the environment' do
      environment.stop!
      environment.update!(updated_at: (Environment::LONG_STOP - 1.day).ago)

      expect { subject }
        .not_to change { environment.reload.state }
        .from('stopping')
    end
  end

  context 'when all stop actions are not complete' do
    it 'does not recover the environment' do
      environment.stop!
      environment.stop_actions.map(&:drop)
      environment.update!(updated_at: (Environment::LONG_STOP + 1.day).ago)

      expect { subject }
        .to change { environment.reload.state }
        .from('stopping').to('available')
    end
  end

  context 'when all stop actions are complete' do
    it 'recovers the environment' do
      environment.stop!
      environment.update!(updated_at: (Environment::LONG_STOP + 1.day).ago)

      expect { subject }
        .not_to change { environment.reload.state }
        .from('stopping')
    end
  end

  context 'when there are no corresponding environment record' do
    let!(:environment) { instance_double('Environment', id: non_existing_record_id) }

    it 'ignores the invalid record' do
      expect { subject }.not_to raise_error
    end
  end
end
