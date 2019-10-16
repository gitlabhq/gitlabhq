# frozen_string_literal: true

require 'spec_helper'

describe Git::ProcessRefChangesService do
  let(:project) { create(:project, :repository) }
  let(:user) { project.owner }
  let(:params) { { changes: git_changes } }

  subject { described_class.new(project, user, params) }

  shared_examples_for 'service for processing ref changes' do |push_service_class|
    let(:service) { double(execute: true) }
    let(:git_changes) { double(branch_changes: [], tag_changes: []) }

    let(:changes) do
      [
        { index: 0, oldrev: Gitlab::Git::BLANK_SHA, newrev: '789012', ref: "#{ref_prefix}/create" },
        { index: 1, oldrev: '123456', newrev: '789012', ref: "#{ref_prefix}/update" },
        { index: 2, oldrev: '123456', newrev: Gitlab::Git::BLANK_SHA, ref: "#{ref_prefix}/delete" }
      ]
    end

    before do
      allow(git_changes).to receive(changes_method).and_return(changes)
    end

    it "calls #{push_service_class}" do
      expect(push_service_class)
        .to receive(:new)
        .with(project, project.owner, hash_including(execute_project_hooks: true))
        .exactly(changes.count).times
        .and_return(service)

      subject.execute
    end

    context 'changes exceed push_event_hooks_limit' do
      def multiple_changes(change, count)
        Array.new(count).map.with_index do |n, index|
          { index: index, oldrev: change[:oldrev], newrev: change[:newrev], ref: "#{change[:ref]}#{n}" }
        end
      end

      let(:push_event_hooks_limit) { 3 }

      let(:changes) do
        multiple_changes(
          { oldrev: '123456', newrev: '789012', ref: "#{ref_prefix}/test" },
          push_event_hooks_limit + 1
        )
      end

      before do
        stub_application_setting(push_event_hooks_limit: push_event_hooks_limit)
      end

      context 'git_push_execute_all_project_hooks is disabled' do
        before do
          stub_feature_flags(git_push_execute_all_project_hooks: false)
        end

        it "calls #{push_service_class} with execute_project_hooks set to false" do
          expect(push_service_class)
            .to receive(:new)
            .with(project, project.owner, hash_including(execute_project_hooks: false))
            .exactly(changes.count).times
            .and_return(service)

          subject.execute
        end
      end

      context 'git_push_execute_all_project_hooks is enabled' do
        before do
          stub_feature_flags(git_push_execute_all_project_hooks: true)
        end

        it "calls #{push_service_class} with execute_project_hooks set to true" do
          expect(push_service_class)
            .to receive(:new)
            .with(project, project.owner, hash_including(execute_project_hooks: true))
            .exactly(changes.count).times
            .and_return(service)

          subject.execute
        end
      end
    end

    context 'pipeline creation' do
      context 'with valid .gitlab-ci.yml' do
        before do
          stub_ci_pipeline_to_return_yaml_file

          allow_any_instance_of(Project)
            .to receive(:commit)
            .and_return(project.commit)

          allow_any_instance_of(Repository)
            .to receive(:branch_exists?)
            .and_return(true)
        end

        context 'when git_push_create_all_pipelines is disabled' do
          before do
            stub_feature_flags(git_push_create_all_pipelines: false)
          end

          it 'creates pipeline for branches and tags' do
            subject.execute

            expect(Ci::Pipeline.pluck(:ref)).to contain_exactly('create', 'update', 'delete')
          end

          it "creates exactly #{described_class::PIPELINE_PROCESS_LIMIT} pipelines" do
            stub_const("#{described_class}::PIPELINE_PROCESS_LIMIT", changes.count - 1)

            expect { subject.execute }.to change { Ci::Pipeline.count }.by(described_class::PIPELINE_PROCESS_LIMIT)
          end
        end

        context 'when git_push_create_all_pipelines is enabled' do
          before do
            stub_feature_flags(git_push_create_all_pipelines: true)
          end

          it 'creates all pipelines' do
            expect { subject.execute }.to change { Ci::Pipeline.count }.by(changes.count)
          end
        end
      end

      context 'with invalid .gitlab-ci.yml' do
        before do
          stub_ci_pipeline_yaml_file(nil)
        end

        it 'does not create a pipeline' do
          expect { subject.execute }.not_to change { Ci::Pipeline.count }
        end
      end
    end
  end

  context 'branch changes' do
    let(:changes_method) { :branch_changes }
    let(:ref_prefix) { 'refs/heads' }

    it_behaves_like 'service for processing ref changes', Git::BranchPushService
  end

  context 'tag changes' do
    let(:changes_method) { :tag_changes }
    let(:ref_prefix) { 'refs/tags' }

    it_behaves_like 'service for processing ref changes', Git::TagPushService
  end
end
