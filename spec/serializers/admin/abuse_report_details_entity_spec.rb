# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::AbuseReportDetailsEntity, feature_category: :insider_threat do
  include Gitlab::Routing

  let_it_be(:report) { build_stubbed(:abuse_report) }
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
        :report
      ])
    end

    it 'correctly exposes `user`', :aggregate_failures do
      user_hash = entity_hash[:user]

      expect(user_hash.keys).to match_array([
        :name,
        :username,
        :avatar_url,
        :email,
        :created_at,
        :last_activity_on,
        :path,
        :admin_path,
        :plan,
        :verification_state,
        :past_closed_reports,
        :similar_open_reports,
        :most_used_ip,
        :last_sign_in_ip,
        :snippets_count,
        :groups_count,
        :notes_count
      ])

      expect(user_hash[:verification_state].keys).to match_array([
        :email,
        :phone,
        :credit_card
      ])

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

    describe 'users plan' do
      it 'does not include the plan' do
        expect(entity_hash[:user][:plan]).to be_nil
      end

      context 'when on .com', :saas, if: Gitlab.ee? do
        before do
          stub_ee_application_setting(should_check_namespace_plan: true)
          create(:namespace_with_plan, plan: :bronze_plan, owner: user)  # rubocop:disable RSpec/FactoryBot/AvoidCreate
        end

        it 'includes the plan' do
          expect(entity_hash[:user][:plan]).to eq('Bronze')
        end
      end
    end

    describe 'users credit card' do
      let(:credit_card_hash) { entity_hash[:user][:credit_card] }

      context 'when the user has no verified credit card' do
        it 'does not expose the credit card' do
          expect(credit_card_hash).to be_nil
        end
      end

      context 'when the user does have a verified credit card' do
        let!(:credit_card) { build_stubbed(:credit_card_validation, user: user) }

        it 'exposes the credit card' do
          expect(credit_card_hash.keys).to match_array([
            :name,
            :similar_records_count,
            :card_matches_link
          ])
        end

        context 'when not on ee', unless: Gitlab.ee? do
          it 'does not include the path to the admin card matches page' do
            expect(credit_card_hash[:card_matches_link]).to be_nil
          end
        end

        context 'when on ee', if: Gitlab.ee? do
          it 'includes the path to the admin card matches page' do
            expect(credit_card_hash[:card_matches_link]).not_to be_nil
          end
        end
      end
    end
  end
end
