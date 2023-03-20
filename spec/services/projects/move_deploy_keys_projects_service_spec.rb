# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MoveDeployKeysProjectsService, feature_category: :continuous_delivery do
  let!(:user) { create(:user) }
  let!(:project_with_deploy_keys) { create(:project, namespace: user.namespace) }
  let!(:target_project) { create(:project, namespace: user.namespace) }

  subject { described_class.new(target_project, user) }

  describe '#execute' do
    before do
      create_list(:deploy_keys_project, 2, project: project_with_deploy_keys)
    end

    it 'moves the user\'s deploy keys from one project to another' do
      expect(project_with_deploy_keys.deploy_keys_projects.count).to eq 2
      expect(target_project.deploy_keys_projects.count).to eq 0

      subject.execute(project_with_deploy_keys)

      expect(project_with_deploy_keys.deploy_keys_projects.count).to eq 0
      expect(target_project.deploy_keys_projects.count).to eq 2
    end

    it 'does not link existent deploy_keys in the current project' do
      target_project.deploy_keys << project_with_deploy_keys.deploy_keys.first

      expect(project_with_deploy_keys.deploy_keys_projects.count).to eq 2
      expect(target_project.deploy_keys_projects.count).to eq 1

      subject.execute(project_with_deploy_keys)

      expect(project_with_deploy_keys.deploy_keys_projects.count).to eq 0
      expect(target_project.deploy_keys_projects.count).to eq 2
    end

    it 'rollbacks changes if transaction fails' do
      allow(subject).to receive(:success).and_raise(StandardError)

      expect { subject.execute(project_with_deploy_keys) }.to raise_error(StandardError)

      expect(project_with_deploy_keys.deploy_keys_projects.count).to eq 2
      expect(target_project.deploy_keys_projects.count).to eq 0
    end

    context 'when remove_remaining_elements is false' do
      let(:options) { { remove_remaining_elements: false } }

      it 'does not remove remaining deploy keys projects' do
        target_project.deploy_keys << project_with_deploy_keys.deploy_keys.first

        subject.execute(project_with_deploy_keys, **options)

        expect(project_with_deploy_keys.deploy_keys_projects.count).not_to eq 0
      end
    end

    context 'when SHA256 fingerprint is missing' do
      before do
        create(:deploy_keys_project, project: target_project)
        DeployKey.all.update_all(fingerprint_sha256: nil)
      end

      it 'moves the user\'s deploy keys from one project to another' do
        combined_keys = project_with_deploy_keys.deploy_keys + target_project.deploy_keys

        subject.execute(project_with_deploy_keys)

        expect(project_with_deploy_keys.deploy_keys.reload).to be_empty
        expect(target_project.deploy_keys.reload).to match_array(combined_keys)
        expect(DeployKey.all.select(:fingerprint_sha256)).to all(be_present)
      end
    end
  end
end
