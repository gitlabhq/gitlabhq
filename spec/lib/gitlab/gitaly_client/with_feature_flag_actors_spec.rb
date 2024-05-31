# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::WithFeatureFlagActors, feature_category: :gitaly do
  let(:user) { create(:user) }
  let(:service) do
    Class.new do
      include Gitlab::GitalyClient::WithFeatureFlagActors
    end.new
  end

  let_it_be(:group) { create(:group) }

  describe '#user_actor' do
    context 'when user is not available in ApplicationContext' do
      it 'returns nil' do
        expect(service.user_actor).to be(nil)
      end
    end

    context 'when user is available in ApplicationContext' do
      around do |example|
        ::Gitlab::ApplicationContext.with_context(user: user) { example.run }
      end

      it 'returns corresponding user record' do
        expect(service.user_actor.flipper_id).to eql(user.flipper_id)
      end
    end

    context 'when user does not exist' do
      around do |example|
        ::Gitlab::ApplicationContext.with_context(user: SecureRandom.uuid) { example.run }
      end

      it 'returns corresponding user record' do
        expect(service.user_actor).to be(nil)
      end
    end
  end

  describe '#repository, #project_actor, #group_actor' do
    context 'when normal project repository' do
      let_it_be(:project) { create(:project, group: group) }
      let(:expected_project) { project }
      let(:expected_group) { Feature::Gitaly::ActorWrapper.new(::Group, project.group.id) }

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { project.repository }
      end

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { project.repository.raw }
      end

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { raw_repo_without_container(project.repository) }
      end
    end

    context 'when project wiki repository' do
      let_it_be(:project) { create(:project, :wiki_repo, group: group) }
      let(:expected_project) { nil }
      let(:expected_group) { nil }

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { project.wiki.repository }
      end

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { project.wiki.repository.raw }
      end

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { raw_repo_without_container(project.wiki.repository) }
      end
    end

    context 'when repository of project in user namespace' do
      let_it_be(:project) { create(:project, namespace: create(:user).namespace) }
      let(:expected_project) { project }
      let(:expected_group) { Feature::Gitaly::ActorWrapper.new(::Group, project.namespace_id) }

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { project.repository }
      end

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { project.repository.raw }
      end

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { raw_repo_without_container(project.repository) }
      end
    end

    context 'when personal snippet' do
      let(:snippet) { create(:personal_snippet) }
      let(:expected_project) { nil }
      let(:expected_group) { nil }

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { snippet.repository }
      end

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { snippet.repository.raw }
      end

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { raw_repo_without_container(snippet.repository) }
      end
    end

    context 'when project snippet' do
      let_it_be(:project) { create(:project, group: group) }
      let(:snippet) { create(:project_snippet, project: project) }
      let(:expected_project) { nil }
      let(:expected_group) { nil }

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { snippet.repository }
      end

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { snippet.repository.raw }
      end

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { raw_repo_without_container(snippet.repository) }
      end
    end

    context 'when project design' do
      let_it_be(:project) { create(:project_with_design, group: group) }
      let(:expected_project) { project }
      let(:expected_group) { group }

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { project.design_repository }
      end

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { project.design_repository.raw }
      end

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { raw_repo_without_container(project.design_repository) }
      end
    end
  end

  describe '#gitaly_client_call' do
    let(:call_arg_1) { double }
    let(:call_arg_2) { double }
    let(:call_arg_3) { double }
    let(:call_result) { double }
    let(:repository_actor) { instance_double(::Repository) }
    let(:user_actor) { instance_double(::User) }
    let(:project_actor) { instance_double(Project) }
    let(:group_actor) { instance_double(Group) }

    before do
      allow(service).to receive(:user_actor).and_return(user_actor)
      allow(service).to receive(:repository_actor).and_return(repository_actor)
      allow(service).to receive(:project_actor).and_return(project_actor)
      allow(service).to receive(:group_actor).and_return(group_actor)
      allow(Gitlab::GitalyClient).to receive(:with_feature_flag_actors).and_call_original
      allow(Gitlab::GitalyClient).to receive(:call).and_return(call_result)
    end

    it 'triggers client call with feature flag actors' do
      result = service.gitaly_client_call(call_arg_1, call_arg_2, karg: call_arg_3)

      expect(Gitlab::GitalyClient).to have_received(:call).with(call_arg_1, call_arg_2, karg: call_arg_3)
      expect(Gitlab::GitalyClient).to have_received(:with_feature_flag_actors).with(
        repository: repository_actor,
        user: user_actor,
        project: project_actor,
        group: group_actor
      )
      expect(result).to be(call_result)
    end

    it 'supports client call with a block' do
      block_double = proc {}
      result = service.gitaly_client_call(call_arg_1, call_arg_2, karg: call_arg_3, &block_double)

      expect(Gitlab::GitalyClient).to have_received(:call) do |*args, **kargs, &block|
        expect(args).to eql([call_arg_1, call_arg_2])
        expect(kargs).to eql({ karg: call_arg_3 })
        expect(block).to be(block_double)
      end
      expect(Gitlab::GitalyClient).to have_received(:with_feature_flag_actors).with(
        repository: repository_actor,
        user: user_actor,
        project: project_actor,
        group: group_actor
      )
      expect(result).to be(call_result)
    end

    context 'when call without repository_actor' do
      before do
        allow(service).to receive(:repository_actor).and_return(nil)
        allow(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).and_call_original
      end

      it 'calls error tracking track_and_raise_for_dev_exception' do
        expect do
          service.gitaly_client_call(call_arg_1, call_arg_2, karg: call_arg_3)
        end.to raise_error(/gitaly_client_call called without setting repository_actor/)

        expect(Gitlab::ErrorTracking).to have_received(:track_and_raise_for_dev_exception).with(
          be_a(Feature::InvalidFeatureFlagError)
        )
      end
    end

    describe '#gitaly_feature_flag_actors' do
      let_it_be(:project) { create(:project) }
      let(:repository_actor) { project.repository }

      let(:user_actor) { instance_double(::User) }
      let(:project_actor) { instance_double(Project) }
      let(:group_actor) { instance_double(Group) }

      before do
        allow(Feature::Gitaly).to receive(:user_actor).and_return(user_actor)
        allow(Feature::Gitaly).to receive(:project_actor).with(project).and_return(project_actor)
        allow(Feature::Gitaly).to receive(:group_actor).with(project).and_return(group_actor)
      end

      it 'returns a hash with collected feature flag actors' do
        result = service.gitaly_feature_flag_actors(repository_actor)
        expect(result).to eql(
          repository: repository_actor,
          user: user_actor,
          project: project_actor,
          group: group_actor
        )

        expect(Feature::Gitaly).to have_received(:user_actor).with(no_args)
        expect(Feature::Gitaly).to have_received(:project_actor).with(project)
        expect(Feature::Gitaly).to have_received(:group_actor).with(project)
      end
    end
  end
end
