# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::Alert, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be_with_refind(:triggered_alert) { create(:alert_management_alert, :triggered, project: project) }
  let_it_be_with_refind(:acknowledged_alert) { create(:alert_management_alert, :acknowledged, project: project) }
  let_it_be_with_refind(:resolved_alert) { create(:alert_management_alert, :resolved, project: project2) }
  let_it_be_with_refind(:ignored_alert) { create(:alert_management_alert, :ignored, project: project2) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:issue).optional }
    it { is_expected.to belong_to(:environment).optional }
    it { is_expected.to have_many(:assignees).through(:alert_assignees) }
    it { is_expected.to have_many(:notes).inverse_of(:noteable) }
    it { is_expected.to have_many(:ordered_notes).class_name('Note').inverse_of(:noteable) }

    it do
      is_expected.to have_many(:user_mentions).class_name('AlertManagement::AlertUserMention')
        .with_foreign_key(:alert_management_alert_id).inverse_of(:alert)
    end
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
          where(:existing_status_event, :new_status, :valid) do
            :resolve      | :triggered    | true
            :resolve      | :acknowledged | true
            :resolve      | :ignored      | true
            :resolve      | :resolved     | true
            :trigger      | :triggered    | false
            :trigger      | :acknowledged | false
            :trigger      | :ignored      | false
            :trigger      | :resolved     | true
            :acknowledge  | :triggered    | false
            :acknowledge  | :acknowledged | false
            :acknowledge  | :ignored      | false
            :acknowledge  | :resolved     | true
            :ignore       | :triggered    | false
            :ignore       | :acknowledged | false
            :ignore       | :ignored      | false
            :ignore       | :resolved     | true
          end

          with_them do
            let(:new_alert) { build(:alert_management_alert, new_status, fingerprint: fingerprint, project: project3) }

            before do
              existing_alert.update!(status_event: existing_status_event)
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

      subject { described_class.for_assignee_username(assignee_username) }

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

    describe '.open_order_by_severity' do
      subject { described_class.where(project: alert_project).open_order_by_severity }

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

    describe '.not_resolved' do
      subject { described_class.not_resolved }

      it { is_expected.to contain_exactly(acknowledged_alert, triggered_alert, ignored_alert) }
    end
  end

  it_behaves_like 'a model including Escalatable'

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

  describe '.find_unresolved_alert' do
    let_it_be(:fingerprint) { SecureRandom.hex }
    let_it_be(:resolved_alert_with_fingerprint) { create(:alert_management_alert, :resolved, project: project, fingerprint: fingerprint) }
    let_it_be(:alert_with_fingerprint_in_other_project) { create(:alert_management_alert, project: project2, fingerprint: fingerprint) }
    let_it_be(:alert_with_fingerprint) { create(:alert_management_alert, project: project, fingerprint: fingerprint) }

    subject { described_class.find_unresolved_alert(project, fingerprint) }

    it { is_expected.to eq(alert_with_fingerprint) }
  end

  describe '.search' do
    let(:alert) { triggered_alert }

    before do
      alert.update!(title: 'Title', description: 'Desc', service: 'Service', monitoring_tool: 'Monitor')
    end

    subject { described_class.search(query) }

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

  describe '#to_reference' do
    it { expect(triggered_alert.to_reference).to eq("^alert##{triggered_alert.iid}") }
  end

  describe '#register_new_event!' do
    subject { alert.register_new_event! }

    let(:alert) { triggered_alert }

    it 'increments the events count by 1' do
      expect { subject }.to change { alert.events }.by(1)
    end
  end

  describe '#resolved_at' do
    subject { resolved_alert.resolved_at }

    it { is_expected.to eq(resolved_alert.ended_at) }
  end

  describe '#resolved_at=' do
    let(:resolve_time) { Time.current }

    it 'sets ended_at' do
      triggered_alert.resolved_at = resolve_time

      expect(triggered_alert.ended_at).to eq(resolve_time)
      expect(triggered_alert.resolved_at).to eq(resolve_time)
    end
  end
end
