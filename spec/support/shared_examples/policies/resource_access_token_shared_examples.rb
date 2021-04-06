# frozen_string_literal: true

RSpec.shared_examples 'Self-managed Core resource access tokens' do
  before do
    allow(::Gitlab).to receive(:com?).and_return(false)
  end

  context 'with owner access' do
    let(:current_user) { owner }

    context 'create resource access tokens' do
      it { is_expected.to be_allowed(:create_resource_access_tokens) }

      context 'when resource access token creation is not allowed' do
        let(:group) { create(:group) }
        let(:project) { create(:project, group: group) }

        before do
          group.namespace_settings.update_column(:resource_access_token_creation_allowed, false)
        end

        it { is_expected.not_to be_allowed(:create_resource_access_tokens) }
      end

      context 'when parent group has project access token creation disabled' do
        let(:parent) { create(:group) }
        let(:group) { create(:group, parent: parent) }
        let(:project) { create(:project, group: group) }

        before do
          parent.namespace_settings.update_column(:resource_access_token_creation_allowed, false)
        end

        it { is_expected.not_to be_allowed(:create_resource_access_tokens) }
      end

      context 'with a personal namespace project' do
        let(:namespace) { create(:namespace) }
        let(:project) { create(:project, namespace: namespace) }

        before do
          project.add_maintainer(current_user)
        end

        it { is_expected.to be_allowed(:create_resource_access_tokens) }
      end
    end

    context 'read resource access tokens' do
      it { is_expected.to be_allowed(:read_resource_access_tokens) }
    end

    context 'destroy resource access tokens' do
      it { is_expected.to be_allowed(:destroy_resource_access_tokens) }
    end
  end

  context 'with developer access' do
    let(:current_user) { developer }

    context 'create resource access tokens' do
      it { is_expected.not_to be_allowed(:create_resource_access_tokens) }
    end

    context 'read resource access tokens' do
      it { is_expected.not_to be_allowed(:read_resource_access_tokens) }
    end

    context 'destroy resource access tokens' do
      it { is_expected.not_to be_allowed(:destroy_resource_access_tokens) }
    end
  end
end

RSpec.shared_examples 'GitLab.com Core resource access tokens' do
  before do
    allow(::Gitlab).to receive(:com?).and_return(true)
    stub_ee_application_setting(should_check_namespace_plan: true)
  end

  context 'with owner access' do
    let(:current_user) { owner }

    context 'create resource access tokens' do
      it { is_expected.not_to be_allowed(:create_resource_access_tokens) }
    end

    context 'read resource access tokens' do
      it { is_expected.not_to be_allowed(:read_resource_access_tokens) }
    end

    context 'destroy resource access tokens' do
      it { is_expected.not_to be_allowed(:destroy_resource_access_tokens) }
    end
  end
end
