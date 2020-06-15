# frozen_string_literal: true

require 'spec_helper'

describe AlertManagement::Alert do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:issue) }
    it { is_expected.to have_many(:assignees).through(:alert_assignees) }
    it { is_expected.to have_many(:notes) }
    it { is_expected.to have_many(:ordered_notes) }
    it { is_expected.to have_many(:user_mentions) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:events) }
    it { is_expected.to validate_presence_of(:severity) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:started_at) }

    it { is_expected.to validate_length_of(:title).is_at_most(200) }
    it { is_expected.to validate_length_of(:description).is_at_most(1000) }
    it { is_expected.to validate_length_of(:service).is_at_most(100) }
    it { is_expected.to validate_length_of(:monitoring_tool).is_at_most(100) }

    context 'when status is triggered' do
      context 'when ended_at is blank' do
        subject { build(:alert_management_alert) }

        it { is_expected.to be_valid }
      end

      context 'when ended_at is present' do
        subject { build(:alert_management_alert, ended_at: Time.current) }

        it { is_expected.to be_invalid }
      end
    end

    context 'when status is acknowledged' do
      context 'when ended_at is blank' do
        subject { build(:alert_management_alert, :acknowledged) }

        it { is_expected.to be_valid }
      end

      context 'when ended_at is present' do
        subject { build(:alert_management_alert, :acknowledged, ended_at: Time.current) }

        it { is_expected.to be_invalid }
      end
    end

    context 'when status is resolved' do
      context 'when ended_at is blank' do
        subject { build(:alert_management_alert, :resolved, ended_at: nil) }

        it { is_expected.to be_invalid }
      end

      context 'when ended_at is present' do
        subject { build(:alert_management_alert, :resolved, ended_at: Time.current) }

        it { is_expected.to be_valid }
      end
    end

    context 'when status is ignored' do
      context 'when ended_at is blank' do
        subject { build(:alert_management_alert, :ignored) }

        it { is_expected.to be_valid }
      end

      context 'when ended_at is present' do
        subject { build(:alert_management_alert, :ignored, ended_at: Time.current) }

        it { is_expected.to be_invalid }
      end
    end

    describe 'fingerprint' do
      let_it_be(:fingerprint) { 'fingerprint' }
      let_it_be(:existing_alert) { create(:alert_management_alert, fingerprint: fingerprint) }
      let(:new_alert) { build(:alert_management_alert, fingerprint: fingerprint, project: project) }

      subject { new_alert }

      context 'adding an alert with the same fingerprint' do
        context 'same project' do
          let(:project) { existing_alert.project }

          it { is_expected.not_to be_valid }
        end

        context 'different project' do
          let(:project) { create(:project) }

          it { is_expected.to be_valid }
        end
      end
    end

    describe 'hosts' do
      subject(:alert) { build(:alert_management_alert, hosts: hosts) }

      context 'over 255 total chars' do
        let(:hosts) { ['111.111.111.111'] * 18 }

        it { is_expected.not_to be_valid }
      end

      context 'under 255 chars' do
        let(:hosts) { ['111.111.111.111'] * 17 }

        it { is_expected.to be_valid }
      end
    end
  end

  describe 'enums' do
    let(:severity_values) do
      { critical: 0, high: 1, medium: 2, low: 3, info: 4, unknown: 5 }
    end

    it { is_expected.to define_enum_for(:severity).with_values(severity_values) }
  end

  describe 'scopes' do
    let_it_be(:project) { create(:project) }
    let_it_be(:triggered_alert) { create(:alert_management_alert, project: project) }
    let_it_be(:resolved_alert) { create(:alert_management_alert, :resolved, project: project) }
    let_it_be(:ignored_alert) { create(:alert_management_alert, :ignored, project: project) }

    describe '.for_iid' do
      subject { AlertManagement::Alert.for_iid(triggered_alert.iid) }

      it { is_expected.to match_array(triggered_alert) }
    end

    describe '.for_status' do
      let(:status) { AlertManagement::Alert::STATUSES[:resolved] }

      subject { AlertManagement::Alert.for_status(status) }

      it { is_expected.to match_array(resolved_alert) }

      context 'with multiple statuses' do
        let(:status) { AlertManagement::Alert::STATUSES.values_at(:resolved, :ignored) }

        it { is_expected.to match_array([resolved_alert, ignored_alert]) }
      end
    end

    describe '.for_fingerprint' do
      let_it_be(:fingerprint) { SecureRandom.hex }
      let_it_be(:alert_with_fingerprint) { create(:alert_management_alert, project: project, fingerprint: fingerprint) }
      let_it_be(:unrelated_alert_with_finger_print) { create(:alert_management_alert, fingerprint: fingerprint) }

      subject { described_class.for_fingerprint(project, fingerprint) }

      it { is_expected.to contain_exactly(alert_with_fingerprint) }
    end

    describe '.counts_by_status' do
      subject { described_class.counts_by_status }

      it do
        is_expected.to eq(
          triggered_alert.status => 1,
          resolved_alert.status => 1,
          ignored_alert.status => 1
        )
      end
    end
  end

  describe '.search' do
    let_it_be(:alert) do
      create(:alert_management_alert,
        title: 'Title',
        description: 'Desc',
        service: 'Service',
        monitoring_tool: 'Monitor'
      )
    end

    subject { AlertManagement::Alert.search(query) }

    context 'does not contain search string' do
      let(:query) { 'something else' }

      it { is_expected.to be_empty }
    end

    context 'title includes query' do
      let(:query) { alert.title.upcase }

      it { is_expected.to contain_exactly(alert) }
    end

    context 'description includes query' do
      let(:query) { alert.description.upcase }

      it { is_expected.to contain_exactly(alert) }
    end

    context 'service includes query' do
      let(:query) { alert.service.upcase }

      it { is_expected.to contain_exactly(alert) }
    end

    context 'monitoring tool includes query' do
      let(:query) { alert.monitoring_tool.upcase }

      it { is_expected.to contain_exactly(alert) }
    end
  end

  describe '#details' do
    let(:payload) do
      {
        'title' => 'Details title',
        'custom' => {
          'alert' => {
            'fields' => %w[one two]
          }
        },
        'yet' => {
          'another' => 'field'
        }
      }
    end
    let(:alert) { build(:alert_management_alert, title: 'Details title', payload: payload) }

    subject { alert.details }

    it 'renders the payload as inline hash' do
      is_expected.to eq(
        'custom.alert.fields' => %w[one two],
        'yet.another' => 'field'
      )
    end
  end

  describe '#to_reference' do
    let(:alert) { build(:alert_management_alert) }

    it { expect(alert.to_reference).to eq('') }
  end

  describe '#trigger' do
    subject { alert.trigger }

    context 'when alert is in triggered state' do
      let(:alert) { create(:alert_management_alert) }

      it 'does not change the alert status' do
        expect { subject }.not_to change { alert.reload.status }
      end
    end

    context 'when alert not in triggered state' do
      let(:alert) { create(:alert_management_alert, :resolved) }

      it 'changes the alert status to triggered' do
        expect { subject }.to change { alert.triggered? }.to(true)
      end

      it 'resets ended at' do
        expect { subject }.to change { alert.reload.ended_at }.to nil
      end
    end
  end

  describe '#acknowledge' do
    subject { alert.acknowledge }

    let(:alert) { create(:alert_management_alert, :resolved) }

    it 'changes the alert status to acknowledged' do
      expect { subject }.to change { alert.acknowledged? }.to(true)
    end

    it 'resets ended at' do
      expect { subject }.to change { alert.reload.ended_at }.to nil
    end
  end

  describe '#resolve' do
    let!(:ended_at) { Time.current }

    subject do
      alert.ended_at = ended_at
      alert.resolve
    end

    context 'when alert already resolved' do
      let(:alert) { create(:alert_management_alert, :resolved) }

      it 'does not change the alert status' do
        expect { subject }.not_to change { alert.reload.status }
      end
    end

    context 'when alert is not resolved' do
      let(:alert) { create(:alert_management_alert) }

      it 'changes alert status to "resolved"' do
        expect { subject }.to change { alert.resolved? }.to(true)
      end
    end
  end

  describe '#ignore' do
    subject { alert.ignore }

    let(:alert) { create(:alert_management_alert, :resolved) }

    it 'changes the alert status to ignored' do
      expect { subject }.to change { alert.ignored? }.to(true)
    end

    it 'resets ended at' do
      expect { subject }.to change { alert.reload.ended_at }.to nil
    end
  end

  describe '#register_new_event!' do
    subject { alert.register_new_event! }

    let(:alert) { create(:alert_management_alert) }

    it 'increments the events count by 1' do
      expect { subject }.to change { alert.events }.by(1)
    end
  end
end
