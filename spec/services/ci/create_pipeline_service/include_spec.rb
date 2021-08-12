# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService do
  context 'include:' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user)    { project.owner }

    let(:ref)      { 'refs/heads/master' }
    let(:source)   { :push }
    let(:service)  { described_class.new(project, user, { ref: ref }) }
    let(:pipeline) { service.execute(source).payload }

    let(:file_location) { 'spec/fixtures/gitlab/ci/external_files/.gitlab-ci-template-1.yml' }

    before do
      allow(project.repository)
        .to receive(:blob_data_at).with(project.commit.id, '.gitlab-ci.yml')
        .and_return(config)

      allow(project.repository)
        .to receive(:blob_data_at).with(project.commit.id, file_location)
        .and_return(File.read(Rails.root.join(file_location)))
    end

    context 'with a local file' do
      let(:config) do
        <<~EOY
        include: #{file_location}
        job:
          script: exit 0
        EOY
      end

      it 'includes the job in the file' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.processables.pluck(:name)).to contain_exactly('job', 'rspec')
      end
    end

    context 'with a local file with rules' do
      let(:config) do
        <<~EOY
        include:
          - local: #{file_location}
            rules:
              - if: $CI_PROJECT_ID == "#{project_id}"
        job:
          script: exit 0
        EOY
      end

      context 'when the rules matches' do
        let(:project_id) { project.id }

        it 'includes the job in the file' do
          expect(pipeline).to be_created_successfully
          expect(pipeline.processables.pluck(:name)).to contain_exactly('job', 'rspec')
        end

        context 'when the FF ci_include_rules is disabled' do
          before do
            stub_feature_flags(ci_include_rules: false)
          end

          it 'includes the job in the file' do
            expect(pipeline).to be_created_successfully
            expect(pipeline.processables.pluck(:name)).to contain_exactly('job', 'rspec')
          end
        end
      end

      context 'when the rules does not match' do
        let(:project_id) { non_existing_record_id }

        it 'does not include the job in the file' do
          expect(pipeline).to be_created_successfully
          expect(pipeline.processables.pluck(:name)).to contain_exactly('job')
        end

        context 'when the FF ci_include_rules is disabled' do
          before do
            stub_feature_flags(ci_include_rules: false)
          end

          it 'includes the job in the file' do
            expect(pipeline).to be_created_successfully
            expect(pipeline.processables.pluck(:name)).to contain_exactly('job', 'rspec')
          end
        end
      end
    end
  end
end
