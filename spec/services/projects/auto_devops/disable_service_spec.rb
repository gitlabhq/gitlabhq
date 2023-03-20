# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Projects::AutoDevops::DisableService, '#execute', feature_category: :auto_devops do
  let(:project) { create(:project, :repository, :auto_devops) }
  let(:auto_devops) { project.auto_devops }

  subject { described_class.new(project).execute }

  context 'when Auto DevOps disabled at instance level' do
    before do
      stub_application_setting(auto_devops_enabled: false)
    end

    it { is_expected.to be_falsy }
  end

  context 'when Auto DevOps enabled at instance level' do
    before do
      stub_application_setting(auto_devops_enabled: true)
    end

    context 'when Auto DevOps explicitly enabled on project' do
      before do
        auto_devops.update!(enabled: true)
      end

      it { is_expected.to be_falsy }
    end

    context 'when Auto DevOps explicitly disabled on project' do
      before do
        auto_devops.update!(enabled: false)
      end

      it { is_expected.to be_falsy }
    end

    context 'when Auto DevOps is implicitly enabled' do
      before do
        auto_devops.update!(enabled: nil)
      end

      context 'when is the first pipeline failure' do
        before do
          create(:ci_pipeline, :failed, :auto_devops_source, project: project)
        end

        it 'disables Auto DevOps for project' do
          subject

          expect(auto_devops.enabled).to eq(false)
        end
      end

      context 'when it is not the first pipeline failure' do
        before do
          create_list(:ci_pipeline, 2, :failed, :auto_devops_source, project: project)
        end

        it 'explicitly disables Auto DevOps for project' do
          subject

          expect(auto_devops.reload.enabled).to eq(false)
        end
      end

      context 'when an Auto DevOps pipeline has succeeded before' do
        before do
          create(:ci_pipeline, :success, :auto_devops_source, project: project)
        end

        it 'does not disable Auto DevOps for project' do
          subject

          expect(auto_devops.reload.enabled).to be_nil
        end
      end
    end

    context 'when project does not have an Auto DevOps record related' do
      let(:project) { create(:project, :repository) }

      before do
        create(:ci_pipeline, :failed, :auto_devops_source, project: project)
      end

      it 'disables Auto DevOps for project' do
        subject
        auto_devops = project.reload.auto_devops

        expect(auto_devops.enabled).to eq(false)
      end

      it 'creates a ProjectAutoDevops record' do
        expect { subject }.to change { ProjectAutoDevops.count }.from(0).to(1)
      end
    end
  end
end
