# frozen_string_literal: true

require 'spec_helper'

describe EnvironmentEntity do
  let(:request) { double('request') }
  let(:entity) do
    described_class.new(environment, request: spy('request'))
  end

  let(:environment) { create(:environment) }
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
    let(:environment) { create(:environment, :will_auto_stop) }

    it 'exposes auto stop related information' do
      expect(subject).to include(:cancel_auto_stop_path, :auto_stop_at)
    end
  end
end
