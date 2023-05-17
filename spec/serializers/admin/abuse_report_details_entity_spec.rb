# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::AbuseReportDetailsEntity, feature_category: :insider_threat do
  include Gitlab::Routing

  let(:report) { build_stubbed(:abuse_report) }
  let(:user) { report.user }
  let(:reporter) { report.reporter }
  let!(:other_report) { create(:abuse_report, user: user) } # rubocop:disable RSpec/FactoryBot/AvoidCreate

  let(:entity) do
    described_class.new(report)
  end

  describe '#as_json' do
    subject(:entity_hash) { entity.as_json }

    it 'exposes correct attributes' do
      expect(entity_hash.keys).to include(
        :user,
        :reporter,
        :report,
        :actions
      )
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
        :other_reports,
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

      expect(user_hash[:other_reports][0].keys).to match_array([
        :created_at,
        :category,
        :report_path
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

    it 'correctly exposes `reporter`' do
      reporter_hash = entity_hash[:reporter]

      expect(reporter_hash.keys).to match_array([
        :name,
        :username,
        :avatar_url,
        :path
      ])
    end

    it 'correctly exposes `report`' do
      report_hash = entity_hash[:report]

      expect(report_hash.keys).to match_array([
        :message,
        :reported_at,
        :category,
        :type,
        :content,
        :url,
        :screenshot
      ])
    end

    it 'correctly exposes `actions`', :aggregate_failures do
      actions_hash = entity_hash[:actions]

      expect(actions_hash.keys).to match_array([
        :user_blocked,
        :block_user_path,
        :remove_user_and_report_path,
        :remove_report_path,
        :reported_user,
        :redirect_path
      ])

      expect(actions_hash[:reported_user].keys).to match_array([
        :name,
        :created_at
      ])
    end
  end
end
