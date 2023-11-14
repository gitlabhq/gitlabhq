# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RecordTargetPlatformsService, '#execute', feature_category: :groups_and_projects do
  let_it_be(:project) { create(:project) }

  let(:detector_service) { Projects::AppleTargetPlatformDetectorService }

  subject(:execute) { described_class.new(project, detector_service).execute }

  context 'when project is an XCode project' do
    def project_setting
      ProjectSetting.find_by_project_id(project.id)
    end

    before do
      double = instance_double(detector_service, execute: [:ios, :osx])
      allow(Projects::AppleTargetPlatformDetectorService).to receive(:new) { double }
    end

    it 'creates a new setting record for the project', :aggregate_failures do
      expect { execute }.to change { ProjectSetting.count }.from(0).to(1)
      expect(ProjectSetting.last.target_platforms).to match_array(%w[ios osx])
    end

    it 'returns array of detected target platforms' do
      expect(execute).to match_array %w[ios osx]
    end

    context 'when a project has an existing setting record' do
      before do
        create(:project_setting, project: project, target_platforms: saved_target_platforms)
      end

      context 'when target platforms changed' do
        let(:saved_target_platforms) { %w[tvos] }

        it 'updates' do
          expect { execute }.to change { project_setting.target_platforms }.from(%w[tvos]).to(%w[ios osx])
        end

        it { is_expected.to match_array %w[ios osx] }
      end

      context 'when target platforms are the same' do
        let(:saved_target_platforms) { %w[osx ios] }

        it 'does not update' do
          expect { execute }.not_to change { project_setting.updated_at }
        end
      end
    end
  end

  context 'when project is not an XCode project' do
    before do
      double = instance_double(Projects::AppleTargetPlatformDetectorService, execute: [])
      allow(Projects::AppleTargetPlatformDetectorService).to receive(:new).with(project) { double }
    end

    it 'does nothing' do
      expect { execute }.not_to change { ProjectSetting.count }
    end

    it { is_expected.to be_nil }
  end
end
