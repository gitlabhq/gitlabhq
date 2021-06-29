# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::Alert do
  let_it_be(:project) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:triggered_alert, reload: true) { create(:alert_management_alert, :triggered, project: project) }
  let_it_be(:acknowledged_alert, reload: true) { create(:alert_management_alert, :acknowledged, project: project) }
  let_it_be(:resolved_alert, reload: true) { create(:alert_management_alert, :resolved, project: project2) }
  let_it_be(:ignored_alert, reload: true) { create(:alert_management_alert, :ignored, project: project2) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:issue).optional }
    it { is_expected.to belong_to(:prometheus_alert).optional }
    it { is_expected.to belong_to(:environment).optional }
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
      subject { triggered_alert }

      context 'when ended_at is blank' do
        it { is_expected.to be_valid }
      end

      context 'when ended_at is present' do
        before do
          triggered_alert.ended_at = Time.current
        end

        it { is_expected.to be_invalid }
      end
    end

    context 'when status is acknowledged' do
      subject { acknowledged_alert }

      context 'when ended_at is blank' do
        it { is_expected.to be_valid }
      end

      context 'when ended_at is present' do
        before do
          acknowledged_alert.ended_at = Time.current
        end

        it { is_expected.to be_invalid }
      end
    end

    context 'when status is resolved' do
      subject { resolved_alert }

      context 'when ended_at is blank' do
        before do
          resolved_alert.ended_at = nil
        end

        it { is_expected.to be_invalid }
      end

      context 'when ended_at is present' do
        it { is_expected.to be_valid }
      end
    end

    context 'when status is ignored' do
      subject { ignored_alert }

      context 'when ended_at is blank' do
        it { is_expected.to be_valid }
      end

      context 'when ended_at is present' do
        before do
          ignored_alert.ended_at = Time.current
        end

        it { is_expected.to be_invalid }
      end
    end

    describe 'fingerprint' do
      let_it_be(:fingerprint) { 'fingerprint' }
      let_it_be(:project3, refind: true) { create(:project) }

      let(:new_alert) { build(:alert_management_alert, fingerprint: fingerprint, project: project3) }

      subject { new_alert }

      context 'adding an alert with the same fingerprint' do
        context 'same project, various states' do
          using RSpec::Parameterized::TableSyntax

          let_it_be(:existing_alert, refind: true) { create(:alert_management_alert, fingerprint: fingerprint, project: project3) }

          # We are only validating uniqueness for non-resolved alerts
          where(:existing_status, :new_status, :valid) do
            :resolved      | :triggered    | true
            :resolved      | :acknowledged | true
            :resolved      | :ignored      | true
            :resolved      | :resolved     | true
            :triggered     | :triggered    | false
            :triggered     | :acknowledged | false
            :triggered     | :ignored      | false
            :triggered     | :resolved     | true
            :acknowledged  | :triggered    | false
            :acknowledged  | :acknowledged | false
            :acknowledged  | :ignored      | false
            :acknowledged  | :resolved     | true
            :ignored       | :triggered    | false
            :ignored       | :acknowledged | false
            :ignored       | :ignored      | false
            :ignored       | :resolved     | true
          end

          with_them do
            let(:new_alert) { build(:alert_management_alert, new_status, fingerprint: fingerprint, project: project3) }

            before do
              existing_alert.change_status_to(existing_status)
            end

            if params[:valid]
              it { is_expected.to be_valid }
            else
              it { is_expected.to be_invalid }
            end
          end
        end

        context 'different project' do
          let_it_be(:existing_alert) { create(:alert_management_alert, fingerprint: fingerprint, project: project2) }

          it { is_expected.to be_valid }
        end
      end
    end

    describe 'hosts' do
      subject(:alert) { triggered_alert }

      before do
        triggered_alert.hosts = hosts
      end

      context 'over 255 total chars' do
        let(:hosts) { ['111.111.111.111'] * 18 }

        it { is_expected.not_to be_valid }
      end

      context 'under 255 chars' do
        let(:hosts) { ['111.111.111.111'] * 17 }

        it { is_expected.to be_valid }
      end

      context 'nested array' do
        let(:hosts) { ['111.111.111.111', ['111.111.111.111']] }

        it { is_expected.not_to be_valid }
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
    describe '.for_iid' do
      subject { project.alert_management_alerts.for_iid(triggered_alert.iid) }

      it { is_expected.to match_array(triggered_alert) }
    end

    describe '.for_status' do
      let(:status) { :resolved }

      subject { AlertManagement::Alert.for_status(status) }

      it { is_expected.to match_array(resolved_alert) }

      context 'with multiple statuses' do
        let(:status) { [:resolved, :ignored] }

        it { is_expected.to match_array([resolved_alert, ignored_alert]) }
      end
    end

    describe '.for_fingerprint' do
      let(:fingerprint) { SecureRandom.hex }
      let(:alert_with_fingerprint) { triggered_alert }
      let(:unrelated_alert_with_finger_print) { resolved_alert }

      subject { described_class.for_fingerprint(project, fingerprint) }

      before do
        alert_with_fingerprint.update!(fingerprint: fingerprint)
        unrelated_alert_with_finger_print.update!(fingerprint: fingerprint)
      end

      it { is_expected.to contain_exactly(alert_with_fingerprint) }
    end

    describe '.for_environment' do
      let(:environment) { create(:environment, project: project) }
      let(:env_alert) { triggered_alert }

      subject { described_class.for_environment(environment) }

      before do
        triggered_alert.update!(environment: environment)
      end

      it { is_expected.to match_array(env_alert) }
    end

    describe '.for_assignee_username' do
      let_it_be(:alert) { triggered_alert }
      let_it_be(:assignee) { create(:user) }

      subject { AlertManagement::Alert.for_assignee_username(assignee_username) }

      before_all do
        alert.update!(assignees: [assignee])
      end

      context 'when matching assignee_username' do
        let(:assignee_username) { assignee.username }

        it { is_expected.to contain_exactly(alert) }
      end

      context 'when unknown assignee_username' do
        let(:assignee_username) { 'unknown username' }

        it { is_expected.to be_empty }
      end

      context 'with empty assignee_username' do
        let(:assignee_username) { ' ' }

        it { is_expected.to be_empty }
      end
    end

    describe '.order_severity_with_open_prometheus_alert' do
      subject { described_class.where(project: alert_project).order_severity_with_open_prometheus_alert }

      let_it_be(:alert_project) { create(:project) }
      let_it_be(:resolved_critical_alert) { create(:alert_management_alert, :resolved, :critical, project: alert_project) }
      let_it_be(:triggered_critical_alert) { create(:alert_management_alert, :triggered, :critical, project: alert_project) }
      let_it_be(:triggered_high_alert) { create(:alert_management_alert, :triggered, :high, project: alert_project) }

      it { is_expected.to eq([triggered_critical_alert, triggered_high_alert]) }
    end

    describe '.counts_by_project_id' do
      subject { described_class.counts_by_project_id }

      it do
        is_expected.to eq(
          project.id => 2,
          project2.id => 2
        )
      end
    end

    describe '.open' do
      subject { described_class.open }

      it { is_expected.to contain_exactly(acknowledged_alert, triggered_alert) }
    end

    describe '.not_resolved' do
      subject { described_class.not_resolved }

      it { is_expected.to contain_exactly(acknowledged_alert, triggered_alert, ignored_alert) }
    end
  end

  describe '.status_value' do
    using RSpec::Parameterized::TableSyntax

    where(:status, :status_value) do
      :triggered    | 0
      :acknowledged | 1
      :resolved     | 2
      :ignored      | 3
      :unknown      | nil
    end

    with_them do
      it 'returns status value by its name' do
        expect(described_class.status_value(status)).to eq(status_value)
      end
    end
  end

  describe '.status_name' do
    using RSpec::Parameterized::TableSyntax

    where(:raw_status, :status) do
      0  | :triggered
      1  | :acknowledged
      2  | :resolved
      3  | :ignored
      -1 | nil
    end

    with_them do
      it 'returns status name by its values' do
        expect(described_class.status_name(raw_status)).to eq(status)
      end
    end
  end

  describe '.counts_by_status' do
    subject { described_class.counts_by_status }

    it do
      is_expected.to eq(
        triggered: 1,
        acknowledged: 1,
        resolved: 1,
        ignored: 1
      )
    end
  end

  describe '.last_prometheus_alert_by_project_id' do
    subject { described_class.last_prometheus_alert_by_project_id }

    let!(:p1_alert_1) { triggered_alert }
    let!(:p1_alert_2) { acknowledged_alert }

    let!(:p2_alert_1) { resolved_alert }
    let!(:p2_alert_2) { ignored_alert }

    it 'returns the latest alert for each project' do
      expect(subject).to contain_exactly(p1_alert_2, p2_alert_2)
    end
  end

  describe '.search' do
    let(:alert) { triggered_alert }

    before do
      alert.update!(title: 'Title', description: 'Desc', service: 'Service', monitoring_tool: 'Monitor')
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

  describe '.reference_pattern' do
    subject { described_class.reference_pattern }

    it { is_expected.to match('gitlab-org/gitlab^alert#123') }
  end

  describe '.link_reference_pattern' do
    subject { described_class.link_reference_pattern }

    it { is_expected.to match(triggered_alert.details_url) }
    it { is_expected.not_to match("#{Gitlab.config.gitlab.url}/gitlab-org/gitlab/alert_management/123") }
    it { is_expected.not_to match("#{Gitlab.config.gitlab.url}/gitlab-org/gitlab/issues/123") }
    it { is_expected.not_to match("gitlab-org/gitlab/-/alert_management/123") }
  end

  describe '.reference_valid?' do
    using RSpec::Parameterized::TableSyntax

    where(:ref, :result) do
      '123456' | true
      '1' | true
      '-1' | false
      nil | false
      '123456891012345678901234567890' | false
    end

    with_them do
      it { expect(described_class.reference_valid?(ref)).to eq(result) }
    end
  end

  describe '.open_status?' do
    using RSpec::Parameterized::TableSyntax

    where(:status, :is_open_status) do
      :triggered    | true
      :acknowledged | true
      :resolved     | false
      :ignored      | false
      nil           | false
    end

    with_them do
      it 'returns true when the status is open status' do
        expect(described_class.open_status?(status)).to eq(is_open_status)
      end
    end
  end

  describe '#to_reference' do
    it { expect(triggered_alert.to_reference).to eq("^alert##{triggered_alert.iid}") }
  end

  describe '#trigger' do
    subject { alert.trigger }

    context 'when alert is in triggered state' do
      let(:alert) { triggered_alert }

      it 'does not change the alert status' do
        expect { subject }.not_to change { alert.reload.status }
      end
    end

    context 'when alert not in triggered state' do
      let(:alert) { resolved_alert }

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

    let(:alert) { resolved_alert }

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
      let(:alert) { resolved_alert }

      it 'does not change the alert status' do
        expect { subject }.not_to change { resolved_alert.reload.status }
      end
    end

    context 'when alert is not resolved' do
      let(:alert) { triggered_alert }

      it 'changes alert status to "resolved"' do
        expect { subject }.to change { alert.resolved? }.to(true)
      end
    end
  end

  describe '#ignore' do
    subject { alert.ignore }

    let(:alert) { resolved_alert }

    it 'changes the alert status to ignored' do
      expect { subject }.to change { alert.ignored? }.to(true)
    end

    it 'resets ended at' do
      expect { subject }.to change { alert.reload.ended_at }.to nil
    end
  end

  describe '#register_new_event!' do
    subject { alert.register_new_event! }

    let(:alert) { triggered_alert }

    it 'increments the events count by 1' do
      expect { subject }.to change { alert.events }.by(1)
    end
  end

  describe '#status_event_for' do
    using RSpec::Parameterized::TableSyntax

    where(:for_status, :event) do
      :triggered     | :trigger
      'triggered'    | :trigger
      :acknowledged  | :acknowledge
      'acknowledged' | :acknowledge
      :resolved      | :resolve
      'resolved'     | :resolve
      :ignored       | :ignore
      'ignored'      | :ignore
      :unknown       | nil
      nil            | nil
      ''             | nil
      1              | nil
    end

    with_them do
      let(:alert) { build(:alert_management_alert, project: project) }

      it 'returns event by status name' do
        expect(alert.status_event_for(for_status)).to eq(event)
      end
    end
  end

  describe '#change_status_to' do
    let_it_be_with_reload(:alert) { create(:alert_management_alert, project: project) }

    context 'with valid statuses' do
      it 'changes the status to triggered' do
        alert.acknowledge! # change to non-triggered status
        expect { alert.change_status_to(:triggered) }.to change { alert.triggered? }.to(true)
      end

      %i(acknowledged resolved ignored).each do |status|
        it "changes the status to #{status}" do
          expect { alert.change_status_to(status) }.to change { alert.public_send(:"#{status}?") }.to(true)
        end
      end
    end

    context 'with invalid status' do
      it 'does not change the current status' do
        expect { alert.change_status_to(nil) }.not_to change { alert.status }
      end
    end
  end
end
