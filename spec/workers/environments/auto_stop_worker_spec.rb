# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::AutoStopWorker, feature_category: :continuous_delivery do
  include CreateEnvironmentsHelpers

  subject { worker.perform(environment_id) }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }

  before_all do
    project.repository.add_branch(developer, 'review/feature', 'master')
  end

  let!(:environment) { create_review_app(user, project, 'review/feature').environment }
  let(:environment_id) { environment.id }
  let(:worker) { described_class.new }
  let(:user) { developer }

  it 'stops the environment' do
    expect { subject }
      .to change { Environment.find_by_name('review/feature').state }
      .from('available').to('stopping')
  end

  it 'executes the stop action' do
    expect { subject }
      .to change { Ci::Build.find_by_name('stop_review_app').status }
      .from('manual').to('pending')
  end

  context 'when user does not have a permission to play the stop action' do
    let(:user) { reporter }

    it 'raises an error' do
      expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  context 'when the environment has already been stopped' do
    before do
      environment.stop!
    end

    it 'does not execute the stop action' do
      expect { subject }
        .not_to change { Ci::Build.find_by_name('stop_review_app').status }
    end
  end

  context 'when there are no deployments and associted stop actions' do
    let!(:environment) { create(:environment) }

    it 'stops the environment' do
      subject

      expect(environment.reload).to be_stopped
    end
  end

  context 'when there are no corresponding environment record' do
    let!(:environment) { double(:environment, id: non_existing_record_id) }

    it 'ignores the invalid record' do
      expect { subject }.not_to raise_error
    end
  end
end
