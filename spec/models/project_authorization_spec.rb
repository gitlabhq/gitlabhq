# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectAuthorization, feature_category: :groups_and_projects do
  describe 'create' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project_1) { create(:project) }

    let(:project_auth) do
      build(
        :project_authorization,
        user: user,
        project: project_1
      )
    end

    it 'sets is_unique' do
      expect { project_auth.save! }.to change { project_auth.is_unique }.to(true)
    end
  end

  describe 'unique user, project authorizations' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project_1) { create(:project) }

    let!(:project_auth) do
      create(
        :project_authorization,
        user: user,
        project: project_1,
        access_level: Gitlab::Access::DEVELOPER
      )
    end

    context 'with duplicate user and project authorization' do
      subject do
        project_auth.dup.tap do |auth|
          auth.project = project_1
          auth.user = user
        end
      end

      it { is_expected.to be_invalid }

      context 'after validation' do
        before do
          subject.valid?
        end

        it 'contains duplicate error' do
          expect(subject.errors[:user]).to include('has already been taken')
        end
      end
    end

    context 'with multiple access levels for the same user and project' do
      subject do
        project_auth.dup.tap do |auth|
          auth.project = project_1
          auth.user = user
          auth.access_level = Gitlab::Access::MAINTAINER
        end
      end

      it { is_expected.to be_invalid }

      context 'after validation' do
        before do
          subject.valid?
        end

        it 'contains duplicate error' do
          expect(subject.errors[:user]).to include('has already been taken')
        end
      end
    end
  end

  describe 'relations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:access_level) }
    it { is_expected.to validate_inclusion_of(:access_level).in_array(Gitlab::Access.all_values) }
  end

  describe 'scopes' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, namespace: user.namespace) }

    describe '.non_guests' do
      let_it_be(:project_original_owner_authorization) { project.owner.project_authorizations.first }
      let_it_be(:project_authorization_guest) { create(:project_authorization, :guest, project: project) }
      let_it_be(:project_authorization_reporter) { create(:project_authorization, :reporter, project: project) }
      let_it_be(:project_authorization_developer) { create(:project_authorization, :developer, project: project) }
      let_it_be(:project_authorization_maintainer) { create(:project_authorization, :maintainer, project: project) }
      let_it_be(:project_authorization_owner) { create(:project_authorization, :owner, project: project) }

      it 'returns all records which are greater than Guests access' do
        expect(described_class.non_guests.map(&:attributes)).to match_array([
          project_authorization_reporter, project_authorization_developer,
          project_authorization_maintainer, project_authorization_owner,
          project_original_owner_authorization
        ].map(&:attributes))
      end
    end

    describe '.owners' do
      let_it_be(:project_original_owner_authorization) { project.owner.project_authorizations.first }
      let_it_be(:project_authorization_owner) { create(:project_authorization, :owner, project: project) }

      before_all do
        create(:project_authorization, :guest, project: project)
        create(:project_authorization, :developer, project: project)
      end

      it 'returns all records which only have Owners access' do
        expect(described_class.owners.map(&:attributes)).to match_array([
          project_original_owner_authorization,
          project_authorization_owner
        ].map(&:attributes))
      end
    end

    describe '.for_project' do
      let_it_be(:project_2) { create(:project, namespace: user.namespace) }
      let_it_be(:project_3) { create(:project, namespace: user.namespace) }

      let_it_be(:project_authorization_3) { project_3.project_authorizations.first }
      let_it_be(:project_authorization_2) { project_2.project_authorizations.first }
      let_it_be(:project_authorization) { project.project_authorizations.first }

      it 'returns all records for the project' do
        expect(described_class.for_project(project).map(&:attributes)).to match_array([
          project_authorization
        ].map(&:attributes))
      end

      it 'returns all records for multiple projects' do
        expect(described_class.for_project([project, project_3]).map(&:attributes)).to match_array([
          project_authorization,
          project_authorization_3
        ].map(&:attributes))
      end
    end

    describe '.for_user' do
      let_it_be(:user_1) { create(:user) }
      let_it_be(:user_2) { create(:user) }

      let_it_be(:project_1) { create(:project) }
      let_it_be(:project_2) { create(:project) }

      let_it_be(:project_auth_1) { create(:project_authorization, user: user_1, project: project_1) }
      let_it_be(:project_auth_2) { create(:project_authorization, user: user_1, project: project_2) }
      let_it_be(:project_auth_3) { create(:project_authorization, user: user_2, project: project_1) }
      let_it_be(:project_auth_4) { create(:project_authorization, user: user_2, project: project_2) }

      subject(:for_user) { described_class.for_user(user_1) }

      it 'returns all records for the user' do
        expect(for_user).to match_array([project_auth_1, project_auth_2])
      end
    end

    describe '.count_by_user_id' do
      subject(:count_by_user_id) { described_class.count_by_user_id }

      it 'returns the number of records grouped by user' do
        expect(count_by_user_id).to eq({ user.id => 1 })
      end
    end
  end

  describe '.insert_all' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project_1) { create(:project) }
    let_it_be(:project_2) { create(:project) }
    let_it_be(:project_3) { create(:project) }

    it 'skips duplicates and inserts the remaining rows without error' do
      create(:project_authorization, user: user, project: project_1, access_level: Gitlab::Access::MAINTAINER)

      attributes = [
        { user_id: user.id, project_id: project_1.id, access_level: Gitlab::Access::MAINTAINER },
        { user_id: user.id, project_id: project_2.id, access_level: Gitlab::Access::MAINTAINER },
        { user_id: user.id, project_id: project_3.id, access_level: Gitlab::Access::MAINTAINER }
      ]

      described_class.insert_all(attributes)

      expect(user.project_authorizations.pluck(:user_id, :project_id, :access_level)).to match_array(attributes.map(&:values))
    end
  end

  context 'with loose foreign key on project_authorizations.user_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let_it_be(:parent) { create(:user) }
      let_it_be(:model) { create(:project_authorization, user: parent) }
    end
  end

  describe '.find_or_create_authorization_for' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:user_id) { user.id }
    let_it_be(:project_id) { project.id }
    let(:access_level) { Gitlab::Access::OWNER }

    subject(:create_project_authorization_record) do
      described_class.find_or_create_authorization_for(user_id, project_id, access_level)
    end

    context 'when record already exists' do
      before_all do
        create(:project_authorization, :owner, project: project, user: user)
      end

      it 'returns existing record' do
        expect { create_project_authorization_record }.not_to change { described_class.count }
      end

      context 'with race condition handling of already existing record' do
        it 'performs the upsert without error' do
          expect(described_class).to receive(:find_by).and_return(nil)

          expect { create_project_authorization_record }.not_to change { described_class.count }
        end
      end
    end

    context 'when no existing record exists' do
      it 'creates a new record with default access_level' do
        expect { create_project_authorization_record }.to change { described_class.count }.by(1)
        expect(user.project_authorizations)
          .to contain_exactly(have_attributes(access_level: access_level, is_unique: true))
      end
    end
  end
end
