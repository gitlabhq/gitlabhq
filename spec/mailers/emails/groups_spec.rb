# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::Groups do
  include EmailSpec::Matchers

  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Need associations
  let(:group) { create(:group) }
  let(:user) { create(:user) }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  before do
    group.add_owner(user)
  end

  describe '#group_was_exported_email' do
    subject { Notify.group_was_exported_email(user, group) }

    it 'sends success email' do
      expect(subject).to have_subject "#{group.name} | Group was exported"
      expect(subject).to have_body_text 'The download link will expire in 24 hours.'
      expect(subject).to have_body_text "groups/#{group.path}/-/download_export"
    end
  end

  describe '#group_was_not_exported_email' do
    let(:shared) { Gitlab::ImportExport::Shared.new(group) }
    let(:error) { Gitlab::ImportExport::Error.new('Error!') }

    before do
      shared.error(error)
    end

    subject { Notify.group_was_not_exported_email(user, group, shared.errors) }

    it 'sends failure email' do
      expect(subject).to have_subject "#{group.name} | Group export error"
      expect(subject).to have_body_text "Group #{group.name} couldn't be exported."
    end
  end

  describe '#group_scheduled_for_deletion' do
    # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Need associations
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group_with_deletion_schedule, owners: user) }
    let_it_be(:sub_group) { create(:group_with_deletion_schedule, parent: group) }
    # rubocop:enable RSpec/FactoryBot/AvoidCreate

    let_it_be(:deletion_adjourned_period) { 7 }
    let_it_be(:deletion_date) { (Time.current + deletion_adjourned_period.days).strftime('%B %-d, %Y') }
    let_it_be(:group_retain_url) { "http://localhost/groups/#{sub_group.full_path}/-/edit#js-advanced-settings" }

    before do
      stub_application_setting(deletion_adjourned_period: deletion_adjourned_period)
    end

    subject { Notify.group_scheduled_for_deletion(user.id, sub_group.id) }

    it 'has the expected content', :aggregate_failures, :freeze_time do
      is_expected.to have_subject("#{sub_group.name} | Group scheduled for deletion")

      is_expected.to have_body_text(
        "has been marked for deletion and will be removed in #{deletion_adjourned_period} days."
      )
      is_expected.to have_body_text(deletion_date)
      is_expected.to have_body_text("href=\"#{group_retain_url}\"")
    end
  end
end
