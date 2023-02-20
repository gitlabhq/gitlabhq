# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectAuthorization do
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
      subject { project_auth.dup }

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

  shared_examples_for 'does not log any detail' do
    it 'does not log any detail' do
      expect(Gitlab::AppLogger).not_to receive(:info)

      execute
    end
  end

  shared_examples_for 'logs the detail' do |batch_size:|
    it 'logs the detail' do
      expect(Gitlab::AppLogger).to receive(:info).with(
        entire_size: 3,
        message: 'Project authorizations refresh performed with delay',
        total_delay: (3 / batch_size.to_f).ceil * ProjectAuthorization::SLEEP_DELAY,
        **Gitlab::ApplicationContext.current
      )

      execute
    end
  end

  describe '.insert_all_in_batches' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project_1) { create(:project) }
    let_it_be(:project_2) { create(:project) }
    let_it_be(:project_3) { create(:project) }

    let(:attributes) do
      [
        { user_id: user.id, project_id: project_1.id, access_level: Gitlab::Access::MAINTAINER },
        { user_id: user.id, project_id: project_2.id, access_level: Gitlab::Access::MAINTAINER },
        { user_id: user.id, project_id: project_3.id, access_level: Gitlab::Access::MAINTAINER }
      ]
    end

    subject(:execute) { described_class.insert_all_in_batches(attributes, per_batch_size) }

    before do
      # Configure as if a replica database is enabled
      allow(::Gitlab::Database::LoadBalancing).to receive(:primary_only?).and_return(false)
    end

    shared_examples_for 'inserts the rows in batches, as per the `per_batch` size, without a delay between each batch' do
      specify do
        expect(described_class).not_to receive(:sleep)

        execute

        expect(user.project_authorizations.pluck(:user_id, :project_id, :access_level)).to match_array(attributes.map(&:values))
      end
    end

    context 'when the total number of records to be inserted is greater than the batch size' do
      let(:per_batch_size) { 2 }

      it 'inserts the rows in batches, as per the `per_batch` size, with a delay between each batch' do
        expect(described_class).to receive(:insert_all).twice.and_call_original
        expect(described_class).to receive(:sleep).twice

        execute

        expect(user.project_authorizations.pluck(:user_id, :project_id, :access_level)).to match_array(attributes.map(&:values))
      end

      it_behaves_like 'logs the detail', batch_size: 2

      context 'when the GitLab installation does not have a replica database configured' do
        before do
          # Configure as if a replica database is not enabled
          allow(::Gitlab::Database::LoadBalancing).to receive(:primary_only?).and_return(true)
        end

        it_behaves_like 'inserts the rows in batches, as per the `per_batch` size, without a delay between each batch'
        it_behaves_like 'does not log any detail'
      end
    end

    context 'when the total number of records to be inserted is less than the batch size' do
      let(:per_batch_size) { 5 }

      it_behaves_like 'inserts the rows in batches, as per the `per_batch` size, without a delay between each batch'
      it_behaves_like 'does not log any detail'
    end
  end

  describe '.delete_all_in_batches_for_project' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user_1) { create(:user) }
    let_it_be(:user_2) { create(:user) }
    let_it_be(:user_3) { create(:user) }
    let_it_be(:user_4) { create(:user) }

    let(:user_ids) { [user_1.id, user_2.id, user_3.id] }

    subject(:execute) do
      described_class.delete_all_in_batches_for_project(
        project: project,
        user_ids: user_ids,
        per_batch: per_batch_size
      )
    end

    before do
      # Configure as if a replica database is enabled
      allow(::Gitlab::Database::LoadBalancing).to receive(:primary_only?).and_return(false)
    end

    before_all do
      create(:project_authorization, user: user_1, project: project)
      create(:project_authorization, user: user_2, project: project)
      create(:project_authorization, user: user_3, project: project)
      create(:project_authorization, user: user_4, project: project)
    end

    shared_examples_for 'removes the project authorizations of the specified users in the current project, without a delay between each batch' do
      specify do
        expect(described_class).not_to receive(:sleep)

        execute

        expect(project.project_authorizations.pluck(:user_id)).not_to include(*user_ids)
      end
    end

    context 'when the total number of records to be removed is greater than the batch size' do
      let(:per_batch_size) { 2 }

      it 'removes the project authorizations of the specified users in the current project, with a delay between each batch' do
        expect(described_class).to receive(:sleep).twice

        execute

        expect(project.project_authorizations.pluck(:user_id)).not_to include(*user_ids)
      end

      it_behaves_like 'logs the detail', batch_size: 2

      context 'when the GitLab installation does not have a replica database configured' do
        before do
          # Configure as if a replica database is not enabled
          allow(::Gitlab::Database::LoadBalancing).to receive(:primary_only?).and_return(true)
        end

        it_behaves_like 'removes the project authorizations of the specified users in the current project, without a delay between each batch'
        it_behaves_like 'does not log any detail'
      end
    end

    context 'when the total number of records to be removed is less than the batch size' do
      let(:per_batch_size) { 5 }

      it_behaves_like 'removes the project authorizations of the specified users in the current project, without a delay between each batch'
      it_behaves_like 'does not log any detail'
    end
  end

  describe '.delete_all_in_batches_for_user' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project_1) { create(:project) }
    let_it_be(:project_2) { create(:project) }
    let_it_be(:project_3) { create(:project) }
    let_it_be(:project_4) { create(:project) }

    let(:project_ids) { [project_1.id, project_2.id, project_3.id] }

    subject(:execute) do
      described_class.delete_all_in_batches_for_user(
        user: user,
        project_ids: project_ids,
        per_batch: per_batch_size
      )
    end

    before do
      # Configure as if a replica database is enabled
      allow(::Gitlab::Database::LoadBalancing).to receive(:primary_only?).and_return(false)
    end

    before_all do
      create(:project_authorization, user: user, project: project_1)
      create(:project_authorization, user: user, project: project_2)
      create(:project_authorization, user: user, project: project_3)
      create(:project_authorization, user: user, project: project_4)
    end

    shared_examples_for 'removes the project authorizations of the specified projects from the current user, without a delay between each batch' do
      specify do
        expect(described_class).not_to receive(:sleep)

        execute

        expect(user.project_authorizations.pluck(:project_id)).not_to include(*project_ids)
      end
    end

    context 'when the total number of records to be removed is greater than the batch size' do
      let(:per_batch_size) { 2 }

      it 'removes the project authorizations of the specified projects from the current user, with a delay between each batch' do
        expect(described_class).to receive(:sleep).twice

        execute

        expect(user.project_authorizations.pluck(:project_id)).not_to include(*project_ids)
      end

      it_behaves_like 'logs the detail', batch_size: 2

      context 'when the GitLab installation does not have a replica database configured' do
        before do
          # Configure as if a replica database is not enabled
          allow(::Gitlab::Database::LoadBalancing).to receive(:primary_only?).and_return(true)
        end

        it_behaves_like 'removes the project authorizations of the specified projects from the current user, without a delay between each batch'
        it_behaves_like 'does not log any detail'
      end
    end

    context 'when the total number of records to be removed is less than the batch size' do
      let(:per_batch_size) { 5 }

      it_behaves_like 'removes the project authorizations of the specified projects from the current user, without a delay between each batch'
      it_behaves_like 'does not log any detail'
    end
  end
end
