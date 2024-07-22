# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::Imports, feature_category: :importers do
  include EmailSpec::Matchers

  let(:user) { build_stubbed(:user) }

  describe '#github_gists_import_errors_email' do
    let(:errors) { { 'gist_id1' => "Title can't be blank", 'gist_id2' => 'Snippet maximum file count exceeded' } }

    subject { Notify.github_gists_import_errors_email('user_id', errors) }

    before do
      allow(User).to receive(:find).and_return(user)
    end

    it 'sends success email' do
      is_expected.to have_subject('GitHub Gists import finished with errors')
      is_expected.to have_content('GitHub gists that were not imported:')
      is_expected.to have_content("Gist with id gist_id1 failed due to error: Title can't be blank.")
      is_expected.to have_content('Gist with id gist_id2 failed due to error: Snippet maximum file count exceeded.')
    end

    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'
  end

  describe '#bulk_import_complete' do
    let(:bulk_import) { build_stubbed(:bulk_import, :finished, :with_configuration) }

    subject { Notify.bulk_import_complete('user_id', 'bulk_import_id') }

    before do
      allow(User).to receive(:find).and_return(user)
      allow(BulkImport).to receive(:find).and_return(bulk_import)
    end

    it 'sends complete email' do
      is_expected.to have_subject("Import from #{bulk_import.configuration.url} completed")
      is_expected.to have_content('Import completed')
      is_expected.to have_content("The import you started on " \
        "#{I18n.l(bulk_import.created_at.to_date, format: :long)} " \
        "from #{bulk_import.configuration.url} has completed. You can now review your import results.")
      is_expected.to have_body_text(history_import_bulk_import_url(bulk_import.id))
    end
  end

  describe '#bulk_import_csv_user_mapping' do
    let(:group) { build_stubbed(:group) }
    let(:failed_count) { 0 }

    subject { Notify.bulk_import_csv_user_mapping('user_id', 'group_id', 689, failed_count) }

    before do
      allow(User).to receive(:find).and_return(user)
      allow(Group).to receive(:find).and_return(group)
    end

    context 'when bulk_import does not have errors' do
      it 'sends success email' do
        is_expected.to have_subject("#{group.name} | Placeholder reassignments completed successfully")
        is_expected.to have_content('Placeholder reassignments completed successfully')
        is_expected.to have_content("All items assigned to placeholder users were reassigned to users in #{group.name}")
        is_expected.to have_content('689 placeholder users matched to users.')
        is_expected.not_to have_content('placeholder users not matched to users.')
        is_expected.to have_body_text(group_group_members_url(group, tab: 'placeholders'))
      end
    end

    context 'when bulk_import has errors' do
      let(:failed_count) { 362 }

      it 'sends failed email' do
        is_expected.to have_subject("#{group.name} | Placeholder reassignments completed with errors")
        is_expected.to have_content('Placeholder reassignments completed with errors')
        is_expected.to have_content("Items assigned to placeholder users were reassigned to users in #{group.name}")
        is_expected.to have_content('689 placeholder users matched to users.')
        is_expected.to have_content('362 placeholder users not matched to users.')
        is_expected.to have_body_text(group_group_members_url(group, tab: 'placeholders', status: 'failed'))
      end
    end

    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'
  end

  describe '#import_source_user_reassign' do
    let(:user) { build_stubbed(:user) }
    let(:group) { build_stubbed(:group) }
    let(:source_user) do
      build_stubbed(:import_source_user, :with_reassigned_by_user, namespace: group, reassign_to_user: user)
    end

    subject { Notify.import_source_user_reassign('user_id') }

    before do
      allow(Import::SourceUser).to receive(:find).and_return(source_user)
    end

    it 'sends reassign email' do
      is_expected.to have_subject("Reassignments on #{group.full_path} waiting for review.")
      is_expected.to have_content("Imported from: #{source_user.source_hostname}")
      is_expected.to have_content("Original user: #{source_user.source_name} (@#{source_user.source_username})")
      is_expected.to have_content("Imported to: #{group.name}")
      is_expected.to have_content("Reassigned to: #{user.name} (@#{user.username})")
      is_expected.to have_content(
        "Reassigned by: #{source_user.reassigned_by_user.name} (@#{source_user.reassigned_by_user.username})"
      )
      is_expected.to have_body_text(import_source_user_url(source_user))
    end

    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'
  end
end
