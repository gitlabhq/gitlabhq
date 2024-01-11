# frozen_string_literal: true

require 'spec_helper'
require 'google/apis/sqladmin_v1beta4'

RSpec.describe GoogleCloud::CreateCloudsqlInstanceWorker, feature_category: :shared do
  let(:random_user) { create(:user) }
  let(:project) { create(:project) }
  let(:worker_options) do
    {
      gcp_project_id: :gcp_project_id,
      instance_name: :instance_name,
      database_version: :database_version,
      environment_name: :environment_name,
      is_protected: true
    }
  end

  context 'when triggered' do
    subject do
      user_id = project.creator.id
      project_id = project.id
      described_class.new.perform(user_id, project_id, worker_options)
    end

    it 'calls CloudSeed::GoogleCloud::SetupCloudsqlInstanceService' do
      allow_next_instance_of(CloudSeed::GoogleCloud::SetupCloudsqlInstanceService) do |service|
        expect(service).to receive(:execute).and_return({ status: :success })
      end

      subject
    end

    context 'when CloudSeed::GoogleCloud::SetupCloudsqlInstanceService fails' do
      subject do
        user_id = random_user.id
        project_id = project.id
        described_class.new.perform(user_id, project_id, worker_options)
      end

      it 'raises error' do
        allow_next_instance_of(CloudSeed::GoogleCloud::SetupCloudsqlInstanceService) do |service|
          expect(service).to receive(:execute).and_return({ status: :error })
        end

        expect { subject }.to raise_error(Exception)
      end
    end
  end
end
