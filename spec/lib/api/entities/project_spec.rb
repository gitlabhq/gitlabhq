# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Entities::Project do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:current_user) { create(:user) }
  let_it_be_with_reload(:grandparent_group) { create(:group) }
  let_it_be_with_reload(:parent_group) do
    create(:group, :allow_runner_registration_token, parent: grandparent_group)
  end

  let_it_be_with_reload(:project) { create(:project, :public, group: parent_group) }
  let(:options) { { current_user: current_user } }
  let(:entity) do
    described_class.new(project, options)
  end

  subject(:json) { entity.as_json }

  context 'without project feature' do
    before do
      project.project_feature.destroy!
      project.reload
    end

    it 'returns a response' do
      expect(json[:issues_access_level]).to be_nil
      expect(json[:repository_access_level]).to be_nil
      expect(json[:merge_requests_access_level]).to be_nil
      expect(json[:package_registry_access_level]).to be_nil
    end
  end

  describe 'import_url' do
    let(:unsafe_import_url) { 'http://user:pass@example.test' }
    let(:safe_import_url) { 'http://example.test' }

    subject(:import_url) { json[:import_url] }

    before do
      project.import_url = unsafe_import_url
    end

    context 'when user cannot admin project' do
      before_all do
        project.add_developer(current_user)
      end

      it { is_expected.to be_nil }
    end

    context 'when a user can admin project' do
      before_all do
        project.add_maintainer(current_user)
      end

      it { is_expected.to eq(safe_import_url) }
    end
  end

  describe '.service_desk_address', feature_category: :service_desk do
    let_it_be(:project) { create(:project, :public) }

    before do
      allow(::ServiceDesk).to receive(:enabled?).with(project).and_return(true)
      stub_incoming_email_setting(enabled: true, address: "incoming+%{key}@example.com")
    end

    context 'when a user can admin issues' do
      before_all do
        project.add_reporter(current_user)
      end

      it 'is present' do
        expect(json[:service_desk_address]).to be_present
      end
    end

    context 'when a user can not admin project' do
      it 'is empty' do
        expect(json[:service_desk_address]).to be_nil
      end
    end
  end

  describe '.archived' do
    where(:project_archived, :parent_archived, :grandparent_archived, :expected_result) do
      true  | false | false | true
      true  | false | true  | true
      true  | true  | false | true
      true  | true  | true  | true
      false | true  | true  | true
      false | true  | false | true
      false | false | true  | true
      false | false | false | false
    end

    with_them do
      before do
        project.update!(archived: project_archived)
        parent_group.update!(archived: parent_archived)
        grandparent_group.update!(archived: grandparent_archived)
      end

      it 'returns the expected result' do
        expect(json[:archived]).to eq(expected_result)
      end
    end
  end

  describe '.shared_with_groups' do
    let_it_be(:group) { create(:group, :private) }

    before_all do
      project.project_group_links.create!(group: group)
    end

    context 'when the current user does not have access to the group' do
      it 'is empty' do
        expect(json[:shared_with_groups]).to be_empty
      end
    end

    context 'when the current user has access to the group' do
      before_all do
        group.add_guest(current_user)
      end

      it 'contains information about the shared group' do
        expect(json[:shared_with_groups]).to contain_exactly(include(group_id: group.id))
      end
    end
  end

  describe '.ci/cd settings' do
    context 'when the user is not an admin' do
      before_all do
        project.add_reporter(current_user)
      end

      it 'does not return ci settings' do
        expect(json[:ci_default_git_depth]).to be_nil
      end
    end

    context 'when the user has admin privileges' do
      before_all do
        project.add_maintainer(current_user)
      end

      it 'returns ci settings' do
        expect(json[:ci_default_git_depth]).to be_present
      end
    end
  end

  describe 'runner token settings', feature_category: :runner_core do
    context 'when the user is not an admin' do
      before_all do
        project.add_reporter(current_user)
      end

      it 'does not return runner token settings' do
        expect(json[:runners_token]).to be_nil
      end
    end

    context 'when the user has admin privileges' do
      before_all do
        project.add_maintainer(current_user)
      end

      it 'returns runner token settings' do
        expect(json[:runners_token]).to be_present
      end
    end
  end

  describe '.package_registry_access_level', feature_category: :package_registry do
    where(:access_level, :expected_value) do
      ProjectFeature::ENABLED  | 'enabled'
      ProjectFeature::DISABLED | 'disabled'
      ProjectFeature::PRIVATE  | 'private'
      ProjectFeature::PUBLIC   | 'public'
    end

    with_them do
      before do
        project.project_feature.update!(package_registry_access_level: access_level)
      end

      it { expect(json[:package_registry_access_level]).to eq(expected_value) }
    end
  end
end
