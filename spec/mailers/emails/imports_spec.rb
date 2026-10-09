# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::Imports, feature_category: :importers do
  include EmailSpec::Matchers

  let(:user) { build_stubbed(:user) }
  let(:offline_warning) do
    s_('UserMapping|This import was created from a file. ' \
      'The source hostname was supplied by the importing user and GitLab cannot verify it.')
  end

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

  shared_examples 'an offline transfer import email' do
    let(:bulk_import) { build_stubbed(:bulk_import, :finished, :with_offline_configuration) }
    let(:configuration) { bulk_import.offline_configuration }
    let(:start_date) { I18n.l(bulk_import.created_at.to_date, format: :long) }

    before do
      allow(User).to receive(:find).and_return(user)
      allow(BulkImport).to receive(:find).and_return(bulk_import)
    end

    it 'reports the import outcome', :aggregate_failures do
      is_expected.to have_subject(expected_title)
      is_expected.to have_content(expected_title)
      is_expected.to have_content(format(
        expected_message_with_prefix,
        start_date: start_date,
        strong_open: '',
        strong_close: '',
        export_prefix: configuration.export_prefix
      ))
      is_expected.to have_content('is not verified, so it may not be trustworthy')
      is_expected.to have_content(expected_results_label)
      is_expected.to have_body_text(history_import_bulk_import_url(bulk_import.id))
    end

    context 'when the bulk import has no configuration' do
      before do
        allow(bulk_import).to receive(:offline_configuration).and_return(nil)
      end

      it 'omits the unverified source section and export prefix', :aggregate_failures do
        is_expected.to have_content(format(expected_message_without_prefix, start_date: start_date))
        is_expected.not_to have_content('is not verified, so it may not be trustworthy')
        is_expected.not_to have_content('from export')
      end
    end

    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'
  end

  describe '#bulk_import_offline_complete' do
    subject { Notify.bulk_import_offline_complete('user_id', 'bulk_import_id') }

    it_behaves_like 'an offline transfer import email' do
      let(:expected_title) { s_('OfflineTransfer|Offline transfer import completed') }
      let(:expected_results_label) { s_('OfflineTransfer|View import results') }
      let(:expected_message_with_prefix) do
        s_('OfflineTransferImport|The offline transfer import you started on %{start_date} from export ' \
          '%{strong_open}%{export_prefix}%{strong_close} has completed. You can now review your import results.')
      end

      let(:expected_message_without_prefix) do
        s_('OfflineTransferImport|The offline transfer import you started on %{start_date} has completed. ' \
          'You can now review your import results.')
      end
    end

    context 'when source_hostname contains credentials' do
      let(:bulk_import) { build_stubbed(:bulk_import, :finished) }
      let(:configuration) do
        build_stubbed(:offline_configuration, source_hostname: 'https://user:secret@gitlab.example.com')
      end

      before do
        allow(User).to receive(:find).and_return(user)
        allow(BulkImport).to receive(:find).and_return(bulk_import)
        allow(bulk_import).to receive(:offline_configuration).and_return(configuration)
      end

      it 'sanitizes the source_hostname' do
        is_expected.to have_content('https://*****:*****@gitlab.example.com')
      end
    end

    context 'when source_hostname is not present' do
      let(:bulk_import) { build_stubbed(:bulk_import, :finished) }
      let(:configuration) { build_stubbed(:offline_configuration, source_hostname: nil) }

      before do
        allow(User).to receive(:find).and_return(user)
        allow(BulkImport).to receive(:find).and_return(bulk_import)
        allow(bulk_import).to receive(:offline_configuration).and_return(configuration)
      end

      it 'omits the unverified source section', :aggregate_failures do
        is_expected.to have_content('Offline transfer import completed')
        is_expected.not_to have_content('is not verified, so it may not be trustworthy')
      end
    end
  end

  describe '#bulk_import_offline_complete_with_errors' do
    subject { Notify.bulk_import_offline_complete_with_errors('user_id', 'bulk_import_id') }

    it_behaves_like 'an offline transfer import email' do
      let(:expected_title) { s_('OfflineTransfer|Offline transfer import completed with errors') }
      let(:expected_results_label) { s_('OfflineTransfer|View import results') }
      let(:expected_message_with_prefix) do
        s_('OfflineTransferImport|The offline transfer import you started on %{start_date} from export ' \
          '%{strong_open}%{export_prefix}%{strong_close} has completed with errors. ' \
          'You can now review your import results.')
      end

      let(:expected_message_without_prefix) do
        s_('OfflineTransferImport|The offline transfer import you started on %{start_date} has completed ' \
          'with errors. You can now review your import results.')
      end
    end
  end

  describe '#bulk_import_offline_failed' do
    subject { Notify.bulk_import_offline_failed('user_id', 'bulk_import_id') }

    it_behaves_like 'an offline transfer import email' do
      let(:expected_title) { s_('OfflineTransfer|Offline transfer import failed') }
      let(:expected_results_label) { s_('OfflineTransfer|View partial import results') }
      let(:expected_message_with_prefix) do
        s_('OfflineTransferImport|The offline transfer import you started on %{start_date} from export ' \
          '%{strong_open}%{export_prefix}%{strong_close} has failed. You can now review your partial import results.')
      end

      let(:expected_message_without_prefix) do
        s_('OfflineTransferImport|The offline transfer import you started on %{start_date} has failed. ' \
          'You can now review your partial import results.')
      end
    end
  end

  describe '#bulk_import_offline_timeout' do
    subject { Notify.bulk_import_offline_timeout('user_id', 'bulk_import_id') }

    it_behaves_like 'an offline transfer import email' do
      let(:expected_title) { s_('OfflineTransfer|Offline transfer import timed out') }
      let(:expected_results_label) { s_('OfflineTransfer|View partial import results') }
      let(:expected_message_with_prefix) do
        s_('OfflineTransferImport|The offline transfer import you started on %{start_date} from export ' \
          '%{strong_open}%{export_prefix}%{strong_close} has timed out. ' \
          'You can now review your partial import results.')
      end

      let(:expected_message_without_prefix) do
        s_('OfflineTransferImport|The offline transfer import you started on %{start_date} has timed out. ' \
          'You can now review your partial import results.')
      end
    end
  end

  describe '#bulk_import_csv_user_mapping' do
    let(:group) { build_stubbed(:group) }
    let(:failed_count) { 0 }
    let(:skipped_count) { 25 }
    let(:success_count) { 689 }

    subject do
      Notify.bulk_import_csv_user_mapping(
        'user_id',
        'group_id',
        success_count: success_count,
        failed_count: failed_count,
        skipped_count: skipped_count
      )
    end

    before do
      allow(User).to receive(:find).and_return(user)
      allow(Group).to receive(:find).and_return(group)
    end

    context 'when bulk_import does not have errors' do
      context 'with skipped row and singular success count' do
        let(:skipped_count) { 1 }
        let(:success_count) { 1 }

        it 'sends success email with skipped rows info' do
          is_expected.to have_subject("#{group.name} | Placeholder reassignments completed successfully")
          is_expected.to have_content(
            "Items assigned to placeholder users have been reassigned to users in #{group.name}")
          is_expected.to have_content('1 placeholder user has been matched to a user.')
          is_expected.to have_content('1 placeholder user has been skipped.')
          is_expected.not_to have_content('placeholder users have not been matched to users.')
          is_expected.to have_body_text(group_group_members_url(group, tab: 'placeholders'))
        end
      end
    end

    context 'when bulk_import has errors' do
      let(:success_count) { 689 }

      context 'with singular failure' do
        let(:failed_count) { 1 }

        it 'sends failed email with skipped rows info' do
          is_expected.to have_subject("#{group.name} | Placeholder reassignments completed with errors")
          is_expected.to have_content('Placeholder reassignments completed with errors')
          is_expected.to have_content(
            "Items assigned to placeholder users have been reassigned to users in #{group.name}")
          is_expected.to have_content('689 placeholder users have been matched to users.')
          is_expected.to have_content('1 placeholder user has not been matched to a user.')
          is_expected.to have_content('25 placeholder users have been skipped.')
          is_expected.to have_body_text(group_group_members_url(group, tab: 'placeholders', status: 'failed'))
        end
      end

      context 'without skipped rows' do
        let(:skipped_count) { 0 }
        let(:failed_count) { 362 }

        it 'sends failed email without skipped rows info' do
          is_expected.to have_subject("#{group.name} | Placeholder reassignments completed with errors")
          is_expected.to have_content('Placeholder reassignments completed with errors')
          is_expected.to have_content(
            "Items assigned to placeholder users have been reassigned to users in #{group.name}")
          is_expected.to have_content('689 placeholder users have been matched to users.')
          is_expected.to have_content('362 placeholder users have not been matched to users.')
          is_expected.not_to have_content('placeholder users have been skipped.')
          is_expected.to have_body_text(group_group_members_url(group, tab: 'placeholders', status: 'failed'))
        end
      end
    end

    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'
  end

  describe '#offline_export_complete' do
    let(:offline_export) { build_stubbed(:offline_export, :finished) }
    let(:source_hostname) { 'https://offline.example.com' }
    let(:configuration) do
      build_stubbed(:offline_configuration, offline_export: offline_export, source_hostname: source_hostname)
    end

    subject { Notify.offline_export_complete('user_id', 'offline_export_id') }

    before do
      allow(User).to receive(:find).and_return(user)
      allow(Import::Offline::Export).to receive(:find).and_return(offline_export)
      allow(offline_export).to receive(:configuration).and_return(configuration)
    end

    it 'sends complete email', :aggregate_failures do
      start_date = I18n.l(offline_export.created_at.to_date, format: :long)

      is_expected.to have_subject('Offline export complete')
      is_expected.to have_content('Export complete')
      is_expected.to have_content(configuration.source_hostname)
      is_expected.to have_content(start_date)
      is_expected.to have_content(configuration.export_prefix)
      is_expected.to have_content('in the configured object storage bucket')
    end

    context 'when source_hostname contains credentials' do
      let(:source_hostname) { 'https://user:secret@gitlab.example.com' }

      it 'sanitizes the source_hostname', :aggregate_failures do
        is_expected.to have_content('https://*****:*****@gitlab.example.com')
        is_expected.not_to have_content('secret')
      end
    end

    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'
  end

  describe '#offline_export_failed' do
    let(:offline_export) { build_stubbed(:offline_export, :failed) }
    let(:source_hostname) { 'https://offline.example.com' }
    let(:configuration) do
      build_stubbed(:offline_configuration, offline_export: offline_export, source_hostname: source_hostname)
    end

    subject { Notify.offline_export_failed('user_id', 'offline_export_id') }

    before do
      allow(User).to receive(:find).and_return(user)
      allow(Import::Offline::Export).to receive(:find).and_return(offline_export)
      allow(offline_export).to receive(:configuration).and_return(configuration)
    end

    it 'sends failed email', :aggregate_failures do
      start_date = I18n.l(offline_export.created_at.to_date, format: :long)

      is_expected.to have_subject('Offline export failed')
      is_expected.to have_content('Export failed')
      is_expected.to have_content(configuration.source_hostname)
      is_expected.to have_content(start_date)
      is_expected.to have_content(configuration.export_prefix)
      is_expected.to have_content('You can safely delete any files found at that path')
      is_expected.to have_content('To try again, start a new export from your source GitLab instance')
    end

    context 'when source_hostname contains credentials' do
      let(:source_hostname) { 'https://user:secret@gitlab.example.com' }

      it 'sanitizes the source_hostname', :aggregate_failures do
        is_expected.to have_content('https://*****:*****@gitlab.example.com')
        is_expected.not_to have_content('secret')
      end
    end

    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'
  end

  describe '#import_source_user_reassign' do
    let(:user) { build_stubbed(:user) }
    let(:group) { build_stubbed(:group) }
    let(:import_type) { 'github' }
    let(:source_user) do
      build_stubbed(
        :import_source_user, :awaiting_approval, :with_reassigned_by_user, namespace: group, reassign_to_user: user,
        import_type: import_type
      )
    end

    subject(:email) { Notify.import_source_user_reassign('user_id') }

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
      is_expected.to have_body_text(
        namespaced_show_import_source_users_url(source_user.namespace_id, source_user.reassignment_token)
      )
    end

    it 'does not describe other imports as offline transfers', :aggregate_failures do
      expect(email.html_part.decoded).not_to include(offline_warning)
      expect(email.text_part.decoded).not_to include(offline_warning)
    end

    context 'when imported through offline transfer' do
      let(:import_type) { Import::SOURCE_OFFLINE_TRANSFER.to_s }

      it 'explains the file-based import and unverified source hostname', :aggregate_failures do
        expect(email.html_part.decoded).to include(offline_warning)
        expect(email.text_part.decoded).to include(offline_warning)
      end
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

  describe '#import_source_user_revoked' do
    let(:user) { build_stubbed(:user) }
    let(:owner) { build_stubbed(:owner) }
    let(:group) { build_stubbed(:group) }
    let(:source_user) do
      build_stubbed(:import_source_user, namespace: group, reassign_to_user: user, reassigned_by_user: owner)
    end

    subject { Notify.import_source_user_revoked('user_id') }

    before do
      allow(Import::SourceUser).to receive(:find).and_return(source_user)
    end

    it 'sends revoked email' do
      is_expected.to deliver_to(owner.email)
      is_expected.to have_subject("Reassignments in #{group.full_path} revoked")
      is_expected.to have_content('Reassignment revoked')
      is_expected.to have_content("#{user.name} (@#{user.username}) has revoked their previously approved reassignment")
      is_expected.to have_content("Contributions already reassigned to #{user.name} remain attributed to them.")
      is_expected.to have_content('To reassign these contributions to another user, go to the Members page')
      is_expected.to have_link('Members page', href: group_group_members_url(group, tab: 'placeholders'))
    end

    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'
  end

  describe '#import_source_user_complete' do
    let(:user) { build_stubbed(:user) }
    let(:group) { build_stubbed(:group) }
    let(:import_type) { 'github' }
    let(:source_user) do
      build_stubbed(
        :import_source_user, :completed, :with_reassigned_by_user, namespace: group, reassign_to_user: user,
        import_type: import_type
      )
    end

    subject(:email) { Notify.import_source_user_complete('user_id') }

    before do
      allow(Import::SourceUser).to receive(:find).and_return(source_user)
    end

    it 'sends reassignment complete email with reference to group owners for help' do
      is_expected.to have_subject("Reassignments in #{group.full_path} completed")
      is_expected.to have_content("Imported from: #{source_user.source_hostname}")
      is_expected.to have_content("Imported to: #{group.name}")
      is_expected.to have_content("Reassigned from: #{source_user.source_name} (@#{source_user.source_username})")
      is_expected.to have_content("Reassigned to: #{user.name} (@#{user.username})")
      is_expected.to have_content(
        "Reassigned by: #{source_user.reassigned_by_user.name} (@#{source_user.reassigned_by_user.username})"
      )
      is_expected.to have_content("contact #{source_user.reassigned_by_user.name} or another group owner.")
      is_expected.to have_link(user.to_reference, href: user_url(user))
      is_expected.to have_link(
        source_user.reassigned_by_user.to_reference,
        href: user_url(source_user.reassigned_by_user)
      )
    end

    it 'does not describe other imports as offline transfers', :aggregate_failures do
      expect(email.html_part.decoded).not_to include(offline_warning)
      expect(email.text_part.decoded).not_to include(offline_warning)
    end

    context 'when imported through offline transfer' do
      let(:import_type) { Import::SOURCE_OFFLINE_TRANSFER.to_s }

      it 'explains the file-based import and unverified source hostname', :aggregate_failures do
        expect(email.html_part.decoded).to include(offline_warning)
        expect(email.text_part.decoded).to include(offline_warning)
      end
    end

    context 'when admin placeholder bypass is enabled' do
      before do
        stub_application_setting(allow_bypass_placeholder_confirmation: true)
      end

      it 'sends reassignment complete email with reference to admins for help' do
        is_expected.to have_subject("Reassignments in #{group.full_path} completed")
        is_expected.to have_content("Imported from: #{source_user.source_hostname}")
        is_expected.to have_content("Imported to: #{group.name}")
        is_expected.to have_content("Reassigned from: #{source_user.source_name} (@#{source_user.source_username})")
        is_expected.to have_content("Reassigned to: #{user.name} (@#{user.username})")
        is_expected.to have_content(
          "Reassigned by: #{source_user.reassigned_by_user.name} (@#{source_user.reassigned_by_user.username})"
        )
        is_expected.to have_content("contact #{source_user.reassigned_by_user.name} or another administrator.")
        is_expected.to have_link(user.to_reference, href: user_url(user))
        is_expected.to have_link(
          source_user.reassigned_by_user.to_reference,
          href: user_url(source_user.reassigned_by_user)
        )
      end
    end

    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'
  end

  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- creates are required in this case
  describe '#project_import_complete' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be_with_reload(:project) { create(:project, creator: user, import_url: 'https://user:password@example.com') }
    let(:user_mapping_enabled) { true }

    subject { Notify.project_import_complete(project.id, user.id, user_mapping_enabled, project.safe_import_url) }

    context 'when user mapping is enabled' do
      context 'with placeholder users awaiting reassignment' do
        before_all do
          create(:import_source_user, namespace: group)

          project.update!(namespace: group)
        end

        context 'when user is a group owner' do
          before_all do
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
        before_all do
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
