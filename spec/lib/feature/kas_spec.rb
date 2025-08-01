# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Feature::Kas, feature_category: :deployment_management do
  let_it_be(:cluster) { create(:cluster_agent) }
  let_it_be(:cluster_2) { create(:cluster_agent) }

  let_it_be(:project) { cluster.project }
  let_it_be(:project_2) { cluster_2.project }

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
          stub_feature_flags(kas_global_flag: false)
        end

        it 'returns false' do
          expect(described_class.enabled_for_any?(:kas_global_flag)).to be(false)
        end
      end

      context 'when the flag defaults to on' do
        it 'returns true' do
          expect(described_class.enabled_for_any?(:kas_global_flag)).to be(true)
        end
      end
    end

    context 'when the flag is enabled for a particular project' do
      before do
        stub_feature_flags(kas_project_flag: project)
      end

      it 'returns true for that project' do
        expect(described_class.enabled_for_any?(:kas_project_flag, project)).to be(true)
      end

      it 'returns false for any other project' do
        expect(described_class.enabled_for_any?(:kas_project_flag, project_2)).to be(false)
      end

      it 'returns false when no project is passed' do
        expect(described_class.enabled_for_any?(:kas_project_flag)).to be(false)
      end
    end

    context 'when the flag is checked with multiple input actors' do
      before do
        stub_feature_flags(kas_flag: project)
      end

      it 'returns true if any of the flag is enabled for any of the input actors' do
        expect(described_class.enabled_for_any?(:kas_flag, project, project.group)).to be(true)
      end
    end
  end

  describe ".server_feature_flags_for_grpc_request" do
    let(:group) { create(:group) }
    let(:user) { create(:user) }

    before do
      stub_feature_flags(
        kas_global_flag: true,
        kas_project_flag: project,
        kas_user_flag: user,
        kas_group_flag: group,
        non_kas_flag: false
      )
    end

    it 'returns a hash of flags starting with the prefix, with dashes instead of underscores' do
      expect(described_class.server_feature_flags_for_grpc_request).to eq(
        'kas-feature-global-flag' => 'true',
        'kas-feature-project-flag' => 'false',
        'kas-feature-user-flag' => 'false',
        'kas-feature-group-flag' => 'false'
      )
    end

    context 'when a project is passed' do
      it 'returns the value for the flag on the given project' do
        expect(described_class.server_feature_flags_for_grpc_request(project: project)).to eq(
          'kas-feature-global-flag' => 'true',
          'kas-feature-project-flag' => 'true',
          'kas-feature-user-flag' => 'false',
          'kas-feature-group-flag' => 'false'
        )

        expect(described_class.server_feature_flags_for_grpc_request(project: project_2)).to eq(
          'kas-feature-global-flag' => 'true',
          'kas-feature-project-flag' => 'false',
          'kas-feature-user-flag' => 'false',
          'kas-feature-group-flag' => 'false'
        )
      end
    end

    context 'when a user is passed' do
      it 'returns the value for the flag on the given user' do
        expect(described_class.server_feature_flags_for_grpc_request(user: user)).to eq(
          'kas-feature-global-flag' => 'true',
          'kas-feature-project-flag' => 'false',
          'kas-feature-user-flag' => 'true',
          'kas-feature-group-flag' => 'false'
        )

        expect(described_class.server_feature_flags_for_grpc_request(user: create(:user))).to eq(
          'kas-feature-global-flag' => 'true',
          'kas-feature-project-flag' => 'false',
          'kas-feature-user-flag' => 'false',
          'kas-feature-group-flag' => 'false'
        )
      end
    end

    context 'when a group is passed' do
      it 'returns the value for the flag on the given group' do
        expect(described_class.server_feature_flags_for_grpc_request(group: group)).to eq(
          'kas-feature-global-flag' => 'true',
          'kas-feature-project-flag' => 'false',
          'kas-feature-user-flag' => 'false',
          'kas-feature-group-flag' => 'true'
        )

        expect(described_class.server_feature_flags_for_grpc_request(group: create(:group))).to eq(
          'kas-feature-global-flag' => 'true',
          'kas-feature-project-flag' => 'false',
          'kas-feature-user-flag' => 'false',
          'kas-feature-group-flag' => 'false'
        )
      end
    end

    context 'when multiple actors are passed' do
      it 'returns the corresponding enablement status for actors' do
        expect(described_class.server_feature_flags_for_grpc_request(project: project_2, group: group)).to eq(
          'kas-feature-global-flag' => 'true',
          'kas-feature-project-flag' => 'false',
          'kas-feature-user-flag' => 'false',
          'kas-feature-group-flag' => 'true'
        )

        expect(described_class.server_feature_flags_for_grpc_request(project: project, group: project_2.group)).to eq(
          'kas-feature-global-flag' => 'true',
          'kas-feature-project-flag' => 'true',
          'kas-feature-user-flag' => 'false',
          'kas-feature-group-flag' => 'false'
        )

        expect(
          described_class.server_feature_flags_for_grpc_request(user: user, project: project, group: group)
        ).to eq(
          'kas-feature-global-flag' => 'true',
          'kas-feature-project-flag' => 'true',
          'kas-feature-user-flag' => 'true',
          'kas-feature-group-flag' => 'true'
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
        expect(described_class.server_feature_flags_for_grpc_request).to eq({})
      end
    end
  end

  describe ".server_feature_flags_for_http_response" do
    let(:group) { create(:group) }
    let(:user) { create(:user) }

    before do
      stub_feature_flags(
        kas_global_flag: true,
        kas_project_flag: project,
        kas_user_flag: user,
        kas_group_flag: group,
        non_kas_flag: false
      )
    end

    it 'returns a hash of flags' do
      expect(described_class.server_feature_flags_for_http_response).to eq(
        'global_flag' => 'true',
        'project_flag' => 'false',
        'user_flag' => 'false',
        'group_flag' => 'false'
      )
    end

    context 'when a project is passed' do
      it 'returns the value for the flag on the given project' do
        expect(described_class.server_feature_flags_for_http_response(project: project)).to eq(
          'global_flag' => 'true',
          'project_flag' => 'true',
          'user_flag' => 'false',
          'group_flag' => 'false'
        )

        expect(described_class.server_feature_flags_for_http_response(project: project_2)).to eq(
          'global_flag' => 'true',
          'project_flag' => 'false',
          'user_flag' => 'false',
          'group_flag' => 'false'
        )
      end
    end

    context 'when a user is passed' do
      it 'returns the value for the flag on the given user' do
        expect(described_class.server_feature_flags_for_http_response(user: user)).to eq(
          'global_flag' => 'true',
          'project_flag' => 'false',
          'user_flag' => 'true',
          'group_flag' => 'false'
        )

        expect(described_class.server_feature_flags_for_http_response(user: create(:user))).to eq(
          'global_flag' => 'true',
          'project_flag' => 'false',
          'user_flag' => 'false',
          'group_flag' => 'false'
        )
      end
    end

    context 'when a group is passed' do
      it 'returns the value for the flag on the given group' do
        expect(described_class.server_feature_flags_for_http_response(group: group)).to eq(
          'global_flag' => 'true',
          'project_flag' => 'false',
          'user_flag' => 'false',
          'group_flag' => 'true'
        )

        expect(described_class.server_feature_flags_for_http_response(group: create(:group))).to eq(
          'global_flag' => 'true',
          'project_flag' => 'false',
          'user_flag' => 'false',
          'group_flag' => 'false'
        )
      end
    end

    context 'when multiple actors are passed' do
      it 'returns the corresponding enablement status for actors' do
        expect(described_class.server_feature_flags_for_http_response(project: project_2, group: group)).to eq(
          'global_flag' => 'true',
          'project_flag' => 'false',
          'user_flag' => 'false',
          'group_flag' => 'true'
        )

        expect(described_class.server_feature_flags_for_http_response(project: project, group: project_2.group)).to eq(
          'global_flag' => 'true',
          'project_flag' => 'true',
          'user_flag' => 'false',
          'group_flag' => 'false'
        )

        expect(
          described_class.server_feature_flags_for_http_response(user: user, project: project, group: group)
        ).to eq(
          'global_flag' => 'true',
          'project_flag' => 'true',
          'user_flag' => 'true',
          'group_flag' => 'true'
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
        expect(described_class.server_feature_flags_for_http_response).to eq({})
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
        expect(described_class.user_actor).to be_nil
      end
    end

    context 'when something else is passed' do
      it 'returns nil' do
        expect(described_class.user_actor(1234)).to be_nil
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
        expect(described_class.project_actor(1234)).to be_nil
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
        expect(described_class.group_actor(1234)).to be_nil
      end
    end
  end
end
