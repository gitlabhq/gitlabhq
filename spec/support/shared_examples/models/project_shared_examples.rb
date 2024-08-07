# frozen_string_literal: true

RSpec.shared_examples 'returns true if project is inactive' do
  using RSpec::Parameterized::TableSyntax

  where(:storage_size, :last_activity_at, :expected_result) do
    1.megabyte  | 1.month.ago | false
    1.megabyte  | 3.years.ago | false
    8.megabytes | 1.month.ago | false
    8.megabytes | 3.years.ago | true
  end

  with_them do
    before do
      stub_application_setting(inactive_projects_min_size_mb: 5)
      stub_application_setting(inactive_projects_send_warning_email_after_months: 24)

      project.statistics.storage_size = storage_size
      project.last_activity_at = last_activity_at
      project.save!
    end

    it 'returns expected result' do
      expect(project.inactive?).to eq(expected_result)
    end
  end
end

RSpec.shared_examples 'checks parent group feature flag' do
  let(:group) { subject_project.group }
  let(:root_group) { group.parent }

  subject { subject_project.public_send(feature_flag_method) }

  context 'when feature flag is disabled globally' do
    before do
      stub_feature_flags(feature_flag => false)
    end

    it { is_expected.to be_falsey }
  end

  context 'when feature flag is enabled globally' do
    it { is_expected.to be_truthy }
  end

  context 'when feature flag is enabled for the root group' do
    before do
      stub_feature_flags(feature_flag => root_group)
    end

    it { is_expected.to be_truthy }
  end

  context 'when feature flag is enabled for the group' do
    before do
      stub_feature_flags(feature_flag => group)
    end

    it { is_expected.to be_truthy }
  end
end

RSpec.shared_examples 'checks parent group and self feature flag' do
  it_behaves_like 'checks parent group feature flag'

  context 'when feature flag is enabled for the project' do
    before do
      stub_feature_flags(feature_flag => subject_project)
    end

    context 'when project belongs to a group' do
      let(:subject_project) { group_project }

      it { is_expected.to be_truthy }
    end

    context 'when project does not belong to a group' do
      let(:subject_project) do
        create(:project, namespace: create(:namespace))
      end

      it { is_expected.to be_truthy }
    end
  end
end

RSpec.shared_examples 'refreshes project.lfs_file_locks_changed_epoch value' do
  it 'updates the lfs_file_locks_changed_epoch value', :clean_gitlab_redis_cache do
    travel_to(1.hour.ago) { project.refresh_lfs_file_locks_changed_epoch }

    original_epoch = project.lfs_file_locks_changed_epoch

    subject

    expect(project.lfs_file_locks_changed_epoch).to be > original_epoch
  end
end

RSpec.shared_examples 'does not refresh project.lfs_file_locks_changed_epoch' do
  it 'does not update the lfs_file_locks_changed_epoch value', :clean_gitlab_redis_cache do
    travel_to(1.hour.ago) { project.refresh_lfs_file_locks_changed_epoch }

    original_epoch = project.lfs_file_locks_changed_epoch

    subject

    expect(project.lfs_file_locks_changed_epoch).to eq original_epoch
  end
end
