# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Feature::Gitaly do
  let_it_be(:project) { create(:project) }
  let_it_be(:project_2) { create(:project) }

  let_it_be(:repository) { project.repository.raw }
  let_it_be(:repository_2) { project_2.repository.raw }

  before do
    allow(Feature::Definition).to receive(:get).and_call_original
    allow(Feature::Definition).to receive(:get).with(:flag).and_return(
      Feature::Definition.new('flag.yml', name: :flag, type: :undefined)
    )
  end

  describe ".enabled_for_any?" do
    context 'when the flag is set globally' do
      context 'when the gate is closed' do
        before do
          stub_feature_flags(gitaly_global_flag: false)
        end

        it 'returns false' do
          expect(described_class.enabled_for_any?(:gitaly_global_flag)).to be(false)
        end
      end

      context 'when the flag defaults to on' do
        it 'returns true' do
          expect(described_class.enabled_for_any?(:gitaly_global_flag)).to be(true)
        end
      end
    end

    context 'when the flag is enabled for a particular project' do
      before do
        stub_feature_flags(gitaly_project_flag: project)
      end

      it 'returns true for that project' do
        expect(described_class.enabled_for_any?(:gitaly_project_flag, project)).to be(true)
      end

      it 'returns false for any other project' do
        expect(described_class.enabled_for_any?(:gitaly_project_flag, project_2)).to be(false)
      end

      it 'returns false when no project is passed' do
        expect(described_class.enabled_for_any?(:gitaly_project_flag)).to be(false)
      end
    end

    context 'when the flag is enabled for a particular repository' do
      before do
        stub_feature_flags(gitaly_repository_flag: repository)
      end

      it 'returns true for that repository' do
        expect(described_class.enabled_for_any?(:gitaly_repository_flag, repository)).to be(true)
      end

      it 'returns false for any other repository' do
        expect(described_class.enabled_for_any?(:gitaly_repository_flag, repository_2)).to be(false)
      end

      it 'returns false when no repository is passed' do
        expect(described_class.enabled_for_any?(:gitaly_repository_flag)).to be(false)
      end
    end

    context 'when the flag is checked with multiple input actors' do
      before do
        stub_feature_flags(gitaly_flag: repository)
      end

      it 'returns true if any of the flag is enabled for any of the input actors' do
        expect(described_class.enabled_for_any?(:gitaly_flag, project, repository)).to be(true)
      end

      it 'returns false if any of the flag is not enabled for any of the input actors' do
        expect(
          described_class.enabled_for_any?(:gitaly_flag, project, project_2, repository_2)
        ).to be(false)
      end
    end
  end

  describe ".server_feature_flags" do
    let(:group) { create(:group) }
    let(:user) { create(:user) }

    before do
      stub_feature_flags(
        gitaly_global_flag: true,
        gitaly_project_flag: project,
        gitaly_repository_flag: repository,
        gitaly_user_flag: user,
        gitaly_group_flag: group,
        non_gitaly_flag: false
      )
    end

    subject { described_class.server_feature_flags }

    it 'returns a hash of flags starting with the prefix, with dashes instead of underscores' do
      expect(subject).to eq(
        'gitaly-feature-global-flag' => 'true',
        'gitaly-feature-project-flag' => 'false',
        'gitaly-feature-repository-flag' => 'false',
        'gitaly-feature-user-flag' => 'false',
        'gitaly-feature-group-flag' => 'false'
      )
    end

    context 'when a project is passed' do
      it 'returns the value for the flag on the given project' do
        expect(described_class.server_feature_flags(project: project)).to eq(
          'gitaly-feature-global-flag' => 'true',
          'gitaly-feature-project-flag' => 'true',
          'gitaly-feature-repository-flag' => 'false',
          'gitaly-feature-user-flag' => 'false',
          'gitaly-feature-group-flag' => 'false'
        )

        expect(described_class.server_feature_flags(project: project_2)).to eq(
          'gitaly-feature-global-flag' => 'true',
          'gitaly-feature-project-flag' => 'false',
          'gitaly-feature-repository-flag' => 'false',
          'gitaly-feature-user-flag' => 'false',
          'gitaly-feature-group-flag' => 'false'
        )
      end
    end

    context 'when a repository is passed' do
      it 'returns the value for the flag on the given repository' do
        expect(described_class.server_feature_flags(repository: repository)).to eq(
          'gitaly-feature-global-flag' => 'true',
          'gitaly-feature-project-flag' => 'false',
          'gitaly-feature-repository-flag' => 'true',
          'gitaly-feature-user-flag' => 'false',
          'gitaly-feature-group-flag' => 'false'
        )

        expect(described_class.server_feature_flags(repository: repository_2)).to eq(
          'gitaly-feature-global-flag' => 'true',
          'gitaly-feature-project-flag' => 'false',
          'gitaly-feature-repository-flag' => 'false',
          'gitaly-feature-user-flag' => 'false',
          'gitaly-feature-group-flag' => 'false'
        )
      end
    end

    context 'when a user is passed' do
      it 'returns the value for the flag on the given user' do
        expect(described_class.server_feature_flags(user: user)).to eq(
          'gitaly-feature-global-flag' => 'true',
          'gitaly-feature-project-flag' => 'false',
          'gitaly-feature-repository-flag' => 'false',
          'gitaly-feature-user-flag' => 'true',
          'gitaly-feature-group-flag' => 'false'
        )

        expect(described_class.server_feature_flags(user: create(:user))).to eq(
          'gitaly-feature-global-flag' => 'true',
          'gitaly-feature-project-flag' => 'false',
          'gitaly-feature-repository-flag' => 'false',
          'gitaly-feature-user-flag' => 'false',
          'gitaly-feature-group-flag' => 'false'
        )
      end
    end

    context 'when a group is passed' do
      it 'returns the value for the flag on the given group' do
        expect(described_class.server_feature_flags(group: group)).to eq(
          'gitaly-feature-global-flag' => 'true',
          'gitaly-feature-project-flag' => 'false',
          'gitaly-feature-repository-flag' => 'false',
          'gitaly-feature-user-flag' => 'false',
          'gitaly-feature-group-flag' => 'true'
        )

        expect(described_class.server_feature_flags(group: create(:group))).to eq(
          'gitaly-feature-global-flag' => 'true',
          'gitaly-feature-project-flag' => 'false',
          'gitaly-feature-repository-flag' => 'false',
          'gitaly-feature-user-flag' => 'false',
          'gitaly-feature-group-flag' => 'false'
        )
      end
    end

    context 'when multiple actors are passed' do
      it 'returns the corresponding enablement status for actors' do
        expect(described_class.server_feature_flags(project: project_2, repository: repository)).to eq(
          'gitaly-feature-global-flag' => 'true',
          'gitaly-feature-project-flag' => 'false',
          'gitaly-feature-repository-flag' => 'true',
          'gitaly-feature-user-flag' => 'false',
          'gitaly-feature-group-flag' => 'false'
        )

        expect(described_class.server_feature_flags(project: project, repository: repository_2)).to eq(
          'gitaly-feature-global-flag' => 'true',
          'gitaly-feature-project-flag' => 'true',
          'gitaly-feature-repository-flag' => 'false',
          'gitaly-feature-user-flag' => 'false',
          'gitaly-feature-group-flag' => 'false'
        )

        expect(
          described_class.server_feature_flags(user: user, project: project, repository: repository, group: group)
        ).to eq(
          'gitaly-feature-global-flag' => 'true',
          'gitaly-feature-project-flag' => 'true',
          'gitaly-feature-repository-flag' => 'true',
          'gitaly-feature-user-flag' => 'true',
          'gitaly-feature-group-flag' => 'true'
        )
      end
    end

    context 'when table does not exist' do
      before do
        allow(Feature::FlipperFeature.database)
          .to receive(:cached_table_exists?)
          .and_return(false)
      end

      it 'returns an empty Hash' do
        expect(subject).to eq({})
      end
    end
  end

  describe ".user_actor" do
    let(:user) { create(:user) }

    context 'when user is passed in' do
      it 'returns a actor wrapper from user' do
        expect(described_class.user_actor(user).flipper_id).to eql(user.flipper_id)
      end
    end

    context 'when called without user and user_id is available in application context' do
      it 'returns a actor wrapper from user_id' do
        ::Gitlab::ApplicationContext.with_context(user: user) do
          expect(described_class.user_actor.flipper_id).to eql(user.flipper_id)
        end
      end
    end

    context 'when called without user and user_id is absent from application context' do
      it 'returns nil' do
        expect(described_class.user_actor).to be(nil)
      end
    end

    context 'when something else is passed' do
      it 'returns nil' do
        expect(described_class.user_actor(1234)).to be(nil)
      end
    end
  end

  describe ".project_actor" do
    let_it_be(:project) { create(:project) }

    context 'when project is passed in' do
      it 'returns a actor wrapper from project' do
        expect(described_class.project_actor(project).flipper_id).to eql(project.flipper_id)
      end
    end

    context 'when something else is passed in' do
      it 'returns nil' do
        expect(described_class.project_actor(1234)).to be(nil)
      end
    end
  end

  describe ".group_actor" do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }

    context 'when project is passed in' do
      it "returns a actor wrapper from project's group" do
        expect(described_class.group_actor(project).flipper_id).to eql(group.flipper_id)
      end
    end

    context 'when something else is passed in' do
      it 'returns nil' do
        expect(described_class.group_actor(1234)).to be(nil)
      end
    end
  end
end
