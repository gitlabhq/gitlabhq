# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::DependentAssociations, feature_category: :user_management do
  describe 'concern inclusion' do
    it 'is included in the User model' do
      expect(User.included_modules).to include(described_class)
    end
  end

  describe 'associations' do
    let(:user) { create(:user) }
    let(:associations_with_nullify) do
      {
        abuse_report_events: { foreign_key: :user_id, class_name: 'ResourceEvents::AbuseReportEvent' },
        authentication_events: {},
        placeholder_user_import_source_users:
          { foreign_key: :placeholder_user_id, class_name: 'Import::SourceUser' },
        reassign_to_user_import_source_users:
          { foreign_key: :reassign_to_user_id, class_name: 'Import::SourceUser' },
        reassigned_by_user_import_source_users: { foreign_key: :reassigned_by_user_id,
                                                  class_name: 'Import::SourceUser' },
        jira_imports: { class_name: 'JiraImportState' },
        project_export_jobs: { foreign_key: :user_id },
        service_desk_custom_email_verifications: {
          class_name: 'ServiceDesk::CustomEmailVerification',
          foreign_key: :triggerer_id
        },
        ssh_signatures: { class_name: 'CommitSignatures::SshSignature' },
        packages: {
          class_name: 'Packages::Package',
          foreign_key: :creator_id
        },
        composer_packages: {
          class_name: 'Packages::Composer::Package',
          foreign_key: :creator_id
        },
        debian_group_distributions: {
          class_name: 'Packages::Debian::GroupDistribution',
          foreign_key: :creator_id
        },
        debian_project_distributions: {
          class_name: 'Packages::Debian::ProjectDistribution',
          foreign_key: :creator_id
        }
      }
    end

    let(:associations_with_destroy) do
      {
        board_group_recent_visits: {},
        board_project_recent_visits: {},
        bulk_import_exports: { foreign_key: :user_id, class_name: 'BulkImports::Export' },
        csv_issue_imports: { class_name: 'Issues::CsvImport' },
        draft_notes: { foreign_key: :author_id },
        group_deletion_schedules: { foreign_key: :user_id },
        group_import_states: { foreign_key: :user_id },
        import_failures: {},
        list_user_preferences: {},
        members_deletion_schedules: { class_name: 'Members::DeletionSchedule' },
        work_item_type_user_preferences: { class_name: 'WorkItems::UserPreference' }
      }
    end

    it 'defines all expected associations with nullify dependency', :aggregate_failures do
      associations_with_nullify.each do |association_name, options|
        association = ::User.reflect_on_association(association_name)

        expect(association).not_to be_nil, "Expected #{association_name} association to be defined"
        expect(association.options[:dependent]).to eq(:nullify),
          "Expected #{association_name} to have dependent: :nullify"

        if options[:foreign_key]
          expect(association.options[:foreign_key]).to eq(options[:foreign_key]),
            "Expected #{association_name} to have foreign_key: #{options[:foreign_key]}"
        end

        if options[:class_name]
          expect(association.options[:class_name]).to eq(options[:class_name]),
            "Expected #{association_name} to have class_name: #{options[:class_name]}"
        end
      end
    end

    it 'defines all expected associations with destroy dependency', :aggregate_failures do
      associations_with_destroy.each do |association_name, options|
        association = ::User.reflect_on_association(association_name)

        expect(association).not_to be_nil, "Expected #{association_name} association to be defined"
        expect(association.options[:dependent]).to eq(:destroy),
          "Expected #{association_name} to have dependent: :destroy"

        if options[:foreign_key]
          expect(association.options[:foreign_key]).to eq(options[:foreign_key]),
            "Expected #{association_name} to have foreign_key: #{options[:foreign_key]}"
        end

        if options[:class_name]
          expect(association.options[:class_name]).to eq(options[:class_name]),
            "Expected #{association_name} to have class_name: #{options[:class_name]}"
        end
      end
    end
  end

  describe 'association behavior' do
    let(:user) { create(:user) }

    context 'with nullify dependency' do
      it 'nullifies abuse_report_events when user is destroyed' do
        event = create(:abuse_report_event, user: user)

        user.destroy!

        event.reload
        expect(event.user_id).to be_nil
      end
    end

    context 'with destroy dependency' do
      it 'destroys draft_notes when user is destroyed' do
        note = create(:draft_note, author: user)

        expect { user.destroy! }.to change { DraftNote.count }.by(-1)
        expect { note.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
