# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::WithFeatureFlagActors do
  let(:user) { create(:user) }
  let(:service) do
    Class.new do
      include Gitlab::GitalyClient::WithFeatureFlagActors
    end.new
  end

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
      let_it_be(:project) { create(:project, group: create(:group)) }
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
      let_it_be(:project) { create(:project, :wiki_repo, group: create(:group)) }
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
      let_it_be(:project) { create(:project, group: create(:group)) }
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
      let_it_be(:project) { create(:project, group: create(:group)) }
      let(:issue) { create(:issue, project: project) }
      let(:design) { create(:design, issue: issue) }

      let(:expected_project) { project }
      let(:expected_group) { project.group }

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { design.repository }
      end

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { design.repository.raw }
      end

      it_behaves_like 'Gitaly feature flag actors are inferred from repository' do
        let(:repository) { raw_repo_without_container(design.repository) }
      end
    end
  end

  describe '#gitaly_client_call' do
    let(:call_arg_1) { double }
    let(:call_arg_2) { double }
    let(:call_arg_3) { double }
    let(:call_result) { double }

    before do
      allow(Gitlab::GitalyClient).to receive(:call).and_return(call_result)
    end

    context 'when actors_aware_gitaly_calls flag is enabled' do
      let(:repository_actor) { instance_double(::Repository) }
      let(:user_actor) { instance_double(::User) }
      let(:project_actor) { instance_double(Project) }
      let(:group_actor) { instance_double(Group) }

      before do
        stub_feature_flags(actors_aware_gitaly_calls: true)

        allow(service).to receive(:user_actor).and_return(user_actor)
        allow(service).to receive(:repository_actor).and_return(repository_actor)
        allow(service).to receive(:project_actor).and_return(project_actor)
        allow(service).to receive(:group_actor).and_return(group_actor)
        allow(Gitlab::GitalyClient).to receive(:with_feature_flag_actors).and_call_original
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
    end

    context 'when actors_aware_gitaly_calls not enabled' do
      before do
        stub_feature_flags(actors_aware_gitaly_calls: false)
      end

      it 'triggers client call without feature flag actors' do
        expect(Gitlab::GitalyClient).not_to receive(:with_feature_flag_actors)

        result = service.gitaly_client_call(call_arg_1, call_arg_2, karg: call_arg_3)

        expect(Gitlab::GitalyClient).to have_received(:call).with(call_arg_1, call_arg_2, karg: call_arg_3)
        expect(result).to be(call_result)
      end
    end
  end
end
