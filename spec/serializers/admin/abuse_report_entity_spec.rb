# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admin::AbuseReportEntity, feature_category: :insider_threat do
  include Gitlab::Routing

  let(:abuse_report) { build_stubbed(:abuse_report) }

  let(:entity) do
    described_class.new(abuse_report)
  end

  before do
    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:markdown_field).with(abuse_report, :message).and_return(abuse_report.message)
    end
  end

  describe '#as_json' do
    subject(:entity_hash) { entity.as_json }

    it 'exposes correct attributes' do
      expect(entity_hash.keys).to include(
        :category,
        :created_at,
        :updated_at,
        :reported_user,
        :reporter,
        :reported_user_path,
        :reporter_path,
        :user_blocked,
        :block_user_path,
        :remove_report_path,
        :remove_user_and_report_path,
        :message,
        :report_path
      )
    end

    it 'correctly exposes `reported user`' do
      expect(entity_hash[:reported_user].keys).to match_array([:name, :created_at])
    end

    it 'correctly exposes `reporter`' do
      expect(entity_hash[:reporter].keys).to match_array([:name])
    end

    it 'correctly exposes :reported_user_path' do
      expect(entity_hash[:reported_user_path]).to eq user_path(abuse_report.user)
    end

    it 'correctly exposes :reporter_path' do
      expect(entity_hash[:reporter_path]).to eq user_path(abuse_report.reporter)
    end

    describe 'user_blocked' do
      subject(:user_blocked) { entity_hash[:user_blocked] }

      context 'when user is blocked' do
        before do
          allow(abuse_report.user).to receive(:blocked?).and_return(true)
        end

        it { is_expected.to be true }
      end

      context 'when user is not blocked' do
        before do
          allow(abuse_report.user).to receive(:blocked?).and_return(false)
        end

        it { is_expected.to be false }
      end
    end

    it 'correctly exposes :block_user_path' do
      expect(entity_hash[:block_user_path]).to eq block_admin_user_path(abuse_report.user)
    end

    it 'correctly exposes :remove_report_path' do
      expect(entity_hash[:remove_report_path]).to eq admin_abuse_report_path(abuse_report)
    end

    it 'correctly exposes :report_path' do
      expect(entity_hash[:report_path]).to eq admin_abuse_report_path(abuse_report)
    end

    it 'correctly exposes :remove_user_and_report_path' do
      expect(entity_hash[:remove_user_and_report_path]).to eq admin_abuse_report_path(abuse_report, remove_user: true)
    end

    it 'correctly exposes :message' do
      expect(entity_hash[:message]).to eq(abuse_report.message)
    end
  end
end
