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
