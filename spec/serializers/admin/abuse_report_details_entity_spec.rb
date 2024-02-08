# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::AbuseReportDetailsEntity, feature_category: :insider_threat do
  include Gitlab::Routing

  let_it_be(:report) { create(:abuse_report) }
  let_it_be(:user) { report.user }
  let_it_be(:reporter) { report.reporter }
  let_it_be(:past_report) { create_default(:abuse_report, :closed, user: user) }
  let_it_be(:similar_open_report) { create_default(:abuse_report, user: user, category: report.category) }

  let(:entity) do
    described_class.new(report)
  end

  describe '#as_json' do
    subject(:entity_hash) { entity.as_json }

    it 'exposes correct attributes' do
      expect(entity_hash.keys).to match_array([
        :user,
        :report,
        :upload_note_attachment_path
      ])
    end

    it 'correctly exposes `user`', :aggregate_failures do
      user_hash = entity_hash[:user]

      expect(user_hash.keys).to include(
        :name,
        :username,
        :avatar_url,
        :email,
        :created_at,
        :last_activity_on,
        :path,
        :admin_path,
        :verification_state,
        :past_closed_reports,
        :similar_open_reports,
        :most_used_ip,
        :last_sign_in_ip,
        :snippets_count,
        :groups_count,
        :notes_count
      )

      expect(user_hash[:verification_state].keys).to include(:email, :credit_card)

      expect(user_hash[:past_closed_reports][0].keys).to match_array([
        :created_at,
        :category,
        :report_path
      ])

      similar_open_report_hash = user_hash[:similar_open_reports][0]
      expect(similar_open_report_hash.keys).to match_array([
        :id,
        :global_id,
        :status,
        :message,
        :reported_at,
        :category,
        :type,
        :content,
        :url,
        :screenshot,
        :update_path,
        :moderate_user_path,
        :reporter
      ])

      similar_reporter_hash = similar_open_report_hash[:reporter]
      expect(similar_reporter_hash.keys).to match_array([
        :name,
        :username,
        :avatar_url,
        :path
      ])
    end

    context 'when report is closed' do
      let(:report) { build_stubbed(:abuse_report, :closed) }

      it 'does not expose `user.similar_open_reports`' do
        user_hash = entity_hash[:user]

        expect(user_hash).not_to include(:similar_open_reports)
      end
    end

    it 'correctly exposes `report`', :aggregate_failures do
      report_hash = entity_hash[:report]

      expect(report_hash.keys).to match_array([
        :id,
        :global_id,
        :status,
        :message,
        :reported_at,
        :category,
        :type,
        :content,
        :url,
        :screenshot,
        :update_path,
        :moderate_user_path,
        :reporter
      ])
    end

    it 'correctly exposes `reporter`' do
      reporter_hash = entity_hash[:report][:reporter]

      expect(reporter_hash.keys).to match_array([
        :name,
        :username,
        :avatar_url,
        :path
      ])
    end
  end
end
