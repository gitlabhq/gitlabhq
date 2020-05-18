# frozen_string_literal: true

require 'spec_helper'

describe EnvironmentEntity do
  include Gitlab::Routing.url_helpers

  let(:request) { double('request') }
  let(:entity) do
    described_class.new(environment, request: spy('request'))
  end

  let_it_be(:user)    { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:environment) { create(:environment, project: project) }

  before do
    allow(entity).to receive(:current_user).and_return(user)
  end

  subject { entity.as_json }

  it 'exposes latest deployment' do
    expect(subject).to include(:last_deployment)
  end

  it 'exposes core elements of environment' do
    expect(subject).to include(:id, :name, :state, :environment_path)
  end

  it 'exposes folder path' do
    expect(subject).to include(:folder_path)
  end

  context 'metrics disabled' do
    before do
      allow(environment).to receive(:has_metrics?).and_return(false)
    end

    it "doesn't expose metrics path" do
      expect(subject).not_to include(:metrics_path)
    end
  end

  context 'metrics enabled' do
    before do
      allow(environment).to receive(:has_metrics?).and_return(true)
    end

    it 'exposes metrics path' do
      expect(subject).to include(:metrics_path)
    end
  end

  context 'with deployment platform' do
    let(:project) { create(:project, :repository) }
    let(:environment) { create(:environment, project: project) }

    context 'when deployment platform is a cluster' do
      before do
        create(:cluster,
               :provided_by_gcp,
               :project,
               environment_scope: '*',
               projects: [project])
      end

      it 'includes cluster_type' do
        expect(subject).to include(:cluster_type)
        expect(subject[:cluster_type]).to eq('project_type')
      end
    end
  end

  context 'with auto_stop_in' do
    let(:environment) { create(:environment, :will_auto_stop, project: project) }

    it 'exposes auto stop related information' do
      project.add_maintainer(user)

      expect(subject).to include(:cancel_auto_stop_path, :auto_stop_at)
    end
  end

  context 'pod_logs' do
    context 'with developer access' do
      before do
        project.add_developer(user)
      end

      it 'does not expose logs keys' do
        expect(subject).not_to include(:logs_path)
        expect(subject).not_to include(:logs_api_path)
        expect(subject).not_to include(:enable_advanced_logs_querying)
      end
    end

    context 'with maintainer access' do
      before do
        project.add_maintainer(user)
      end

      it 'exposes logs keys' do
        expect(subject).to include(:logs_path)
        expect(subject).to include(:logs_api_path)
        expect(subject).to include(:enable_advanced_logs_querying)
      end

      it 'uses k8s api when ES is not available' do
        expect(subject[:logs_api_path]).to eq(k8s_project_logs_path(project, environment_name: environment.name, format: :json))
      end

      it 'uses ES api when ES is available' do
        allow(environment).to receive(:elastic_stack_available?).and_return(true)

        expect(subject[:logs_api_path]).to eq(elasticsearch_project_logs_path(project, environment_name: environment.name, format: :json))
      end
    end
  end
end
