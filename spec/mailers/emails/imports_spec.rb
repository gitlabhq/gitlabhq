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
    let(:bulk_import) { build_stubbed(:bulk_import, :finished) }
    let!(:bulk_configuration) { build(:bulk_import_configuration, bulk_import: bulk_import, url: url) }
    let(:url) { 'http://user:secret@example.com' }
    let(:masked_url) { 'http://*****:*****@example.com' }

    subject { Notify.bulk_import_complete('user_id', 'bulk_import_id') }

    before do
      allow(User).to receive(:find).and_return(user)
      allow(BulkImport).to receive(:find).and_return(bulk_import)
    end

    it 'sends complete email' do
      is_expected.to have_subject("Import from #{masked_url} completed")
      is_expected.to have_content('Import completed')
      is_expected.to have_content("The import you started on " \
        "#{I18n.l(bulk_import.created_at.to_date, format: :long)} " \
        "from #{masked_url} has completed. You can now review your import results.")
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
      build_stubbed(
        :import_source_user, :awaiting_approval, :with_reassigned_by_user, namespace: group, reassign_to_user: user
      )
    end

    subject { Notify.import_source_user_reassign('user_id') }

    before do
      allow(Import::SourceUser).to receive(:find).and_return(source_user)
    end

    it 'sends reassign email' do
      is_expected.to have_subject("Reassignments in #{group.full_path} waiting for review")
      is_expected.to have_content("Imported from: #{source_user.source_hostname}")
      is_expected.to have_content("Original user: #{source_user.source_name} (@#{source_user.source_username})")
      is_expected.to have_content("Imported to: #{group.name}")
      is_expected.to have_content("Reassigned to: #{user.name} (@#{user.username})")
      is_expected.to have_content(
        "Reassigned by: #{source_user.reassigned_by_user.name} (@#{source_user.reassigned_by_user.username})"
      )
      is_expected.to have_body_text(import_source_user_url(source_user.reassignment_token))
    end

    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'
  end

  describe '#import_source_user_rejected' do
    let(:user) { build_stubbed(:user) }
    let(:owner) { build_stubbed(:owner) }
    let(:group) { build_stubbed(:group) }
    let(:source_user) do
      build_stubbed(:import_source_user, namespace: group, reassign_to_user: user, reassigned_by_user: owner)
    end

    subject { Notify.import_source_user_rejected('user_id') }

    before do
      allow(Import::SourceUser).to receive(:find).and_return(source_user)
    end

    it 'sends rejected email' do
      is_expected.to deliver_to(owner.email)
      is_expected.to have_subject("Reassignments in #{group.full_path} rejected")
      is_expected.to have_content('Reassignment rejected')
      is_expected.to have_content("#{user.name} (@#{user.username}) has declined your request")
      is_expected.to have_body_text(group_group_members_url(group, tab: 'placeholders'))
    end

    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'
  end

  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- creates are required in this case
  describe '#project_import_complete' do
    let(:user) { create(:user) }
    let(:owner) { create(:owner) }
    let(:group) { create(:group) }
    let(:project) { create(:project, creator: user, import_url: 'https://user:password@example.com') }
    let(:user_mapping_enabled) { true }

    subject { Notify.project_import_complete(project.id, user.id, user_mapping_enabled, project.safe_import_url) }

    context 'when user mapping is enabled' do
      context 'with placeholder users awaiting reassignment' do
        before do
          create(:import_source_user, namespace: group)

          project.update!(namespace: group)
        end

        context 'when user is a group owner' do
          before do
            group.add_owner(user)
          end

          it 'mentions owner role can reassign placeholder users' do
            is_expected.to deliver_to(user)
            is_expected.to have_subject("#{project.name} | Import from https://*****:*****@example.com completed")
            is_expected.to have_content('You can reassign contributions on the "Members" page of the group.')
            is_expected.to have_content('Reassign contributions')
          end
        end

        context 'when user is not an owner' do
          it 'mentions owners can reassign contributions' do
            content = 'Users with the Owner role for the group can reassign contributions on the "Members" page.'

            is_expected.to deliver_to(user)
            is_expected.to have_subject("#{project.name} | Import from https://*****:*****@example.com completed")
            is_expected.to have_content(content)
          end
        end
      end

      context 'without placeholder users awaiting reassignment' do
        before do
          group.add_owner(user)
        end

        it 'does not mention contributions reassignment' do
          create(:import_source_user, :pending_reassignment, namespace: group)

          is_expected.to deliver_to(user)
          is_expected.to have_subject("#{project.name} | Import from https://*****:*****@example.com completed")
          is_expected.to have_content('You can now review your import results.')
        end
      end

      context 'when project is in user namespace' do
        it 'does not mention contributions reassignment' do
          create(:import_source_user, :pending_reassignment, namespace: group)

          is_expected.to deliver_to(user)
          is_expected.to have_subject("#{project.name} | Import from https://*****:*****@example.com completed")
          is_expected.to have_content('You can now review your import results.')
          is_expected.to have_content('View import results')
        end
      end
    end

    context 'when user mapping is disabled' do
      let(:user_mapping_enabled) { false }

      it 'does not mention contributions reassignment' do
        is_expected.to deliver_to(user)
        is_expected.to have_subject("#{project.name} | Import from https://*****:*****@example.com completed")
        is_expected.to have_content('You can now review your import results.')
      end
    end

    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'
  end
  # rubocop:enable RSpec/FactoryBot/AvoidCreate
end
