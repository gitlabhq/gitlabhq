# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AntiAbuse::Event, type: :model, feature_category: :insider_threat do
  let_it_be(:event) { create(:abuse_event) }
  let_it_be(:user, reload: true) { create(:admin) }

  subject { event }

  it { is_expected.to be_valid }

  describe "associations" do
    it { is_expected.to belong_to(:user).class_name("User").inverse_of(:abuse_events) }
    it { is_expected.to belong_to(:abuse_report).inverse_of(:abuse_events) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_presence_of(:category) }
    it { is_expected.to validate_presence_of(:user).on(:create) }
  end

  describe 'enums' do
    let(:categories) do
      {
        spam: 0,  # spamcheck
        virus: 1, # VirusTotal
        fraud: 2, # Arkos, Telesign
        ci_cd: 3  # PVS
      }
    end

    let(:sources) do
      {
        spamcheck: 0,
        virus_total: 1,
        arkose_custom_score: 2,
        arkose_global_score: 3,
        telesign: 4,
        pvs: 5
      }
    end

    it { is_expected.to define_enum_for(:source).with_values(**sources) }
    it { is_expected.to define_enum_for(:category).with_values(**categories) }
  end
end
