# frozen_string_literal: true

require 'spec_helper'

module WorkItems
  module DataSync
    module AssociationsHelpers
      include Gitlab::Utils::StrongMemoize

      BASE_ASSOCIATIONS = {
        base_associations: [
          :author, :updated_by, :project, :duplicated_to, :last_edited_by, :closed_by, :work_item_type,
          :correct_work_item_type, :moved_to, :moved_from, :namespace
        ]
      }.freeze

      WIDGETS_ASSOCIATIONS = {
        assignees: [:assignees, :issue_assignees, :assignees_by_name_and_id],
        award_emoji: [:award_emoji],
        crm_contacts: [:customer_relations_contacts, :issue_customer_relations_contacts],
        current_user_todos: [:todos],
        description: [:description_versions],
        designs: [:designs, :design_versions], # DesignManagement::Action ???
        development: [:merge_requests_closing_issues],
        email_participants: [:issue_email_participants, :email],
        hierarchy: [
          :work_item_parent, :work_item_children, :work_item_children_by_relative_position, :parent_link, :child_links
        ],
        labels: [:label_links, :labels, :resource_label_events],
        linked_items: [], # linked_work_items
        milestone: [:milestone, :resource_milestone_events],
        notes: [:notes, :note_authors, :user_note_authors],
        notifications: [:sent_notifications, :subscriptions],
        participants: [:user_mentions],
        start_and_due_date: [:dates_source],
        time_tracking: [:timelogs],
        rolledup_dates: [],
        status: [],
        weight: [:weights_source]
      }.freeze

      NON_WIDGETS_ASSOCIATIONS = {
        tbd: [
          :events, :assignment_events, :resource_state_events, :metrics,
          :incident_management_issuable_escalation_status, :incident_management_timeline_events, :issuable_severity,
          :sentry_issue, :alert_management_alert, :alert_management_alerts, :user_agent_detail, :zoom_meetings,
          :search_data
        ]
      }.freeze

      def base_associations
        BASE_ASSOCIATIONS
      end

      def widgets_associations
        WIDGETS_ASSOCIATIONS
      end

      def non_widgets_associations
        NON_WIDGETS_ASSOCIATIONS
      end

      def known_transferable_associations
        [
          base_associations.values,
          widgets_associations.values,
          non_widgets_associations.values
        ].flatten
      end
      strong_memoize_attr :known_transferable_associations

      def missing_transfer_callbacks(missing_callbacks)
        <<~MSG
          Following association(s) are not being handled by move and clone services:
           - #{missing_callbacks.join("\n - ")}

          Please make sure that these associations have a transfer callback defined in one of the following locations:
           - app/services/work_items/data_sync/widgets
           - app/services/work_items/data_sync/non_widgets
           - ee/app/services/work_items/data_sync/widgets
           - ee/app/services/work_items/data_sync/non_widgets
        MSG
      end

      def missing_work_item_association(missing_work_item_association)
        <<~MSG
          Following association(s) are declared as being handled by move and clone services callbacks but are no longer
          present in WorkItem model:
           - #{missing_work_item_association.join("\n - ")}

          Please check if these associations were removed from WorkItem model and remove the corresponding callbacks
          and update corresponding collection of associations in WorkItems::DataSync::AssociationsHelpers or
          EE::WorkItems::DataSync::AssociationsHelpers:
           - BASE_ASSOCIATIONS
           - WIDGETS_ASSOCIATIONS
           - NON_WIDGETS_ASSOCIATIONS
        MSG
      end

      def duplicate_associations(associations)
        duplicate_locations = {}
        duplicates = associations.group_by { |assoc| assoc }.select { |_name, value| value.size > 1 }.map(&:first)

        [
          base_associations,
          widgets_associations,
          non_widgets_associations
        ].each do |constant|
          constant.each do |callback, associations|
            matches = associations & duplicates
            matches.each do |match|
              duplicate_locations[match] ||= []
              duplicate_locations[match] << callback
            end
          end
        end

        duplicate_info = duplicate_locations.map do |association_name, callback_name|
          " - #{association_name} (found in: #{callback_name})"
        end.join("\n")

        <<~MSG
          Following associations are being handled by more than one callback:
          #{duplicate_info}

          Please make sure that these associations are handled by only one callback.
        MSG
      end
    end
  end
end

WorkItems::DataSync::AssociationsHelpers.prepend_mod
