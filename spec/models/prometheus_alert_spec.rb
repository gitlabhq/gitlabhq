# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PrometheusAlert do
  let_it_be(:project) { build(:project) }

  let(:metric) { build(:prometheus_metric) }

  describe '.distinct_projects' do
    let(:project1) { create(:project) }
    let(:project2) { create(:project) }

    before do
      create(:prometheus_alert, project: project1)
      create(:prometheus_alert, project: project1)
      create(:prometheus_alert, project: project2)
    end

    subject { described_class.distinct_projects.count }

    it 'returns a count of all distinct projects which have an alert' do
      expect(subject).to eq(2)
    end
  end

  describe 'operators' do
    it 'contains the correct equality operator' do
      expect(described_class::OPERATORS_MAP.values).to include('==')
      expect(described_class::OPERATORS_MAP.values).not_to include('=')
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:environment) }
    it { is_expected.to belong_to(:prometheus_metric) }
    it { is_expected.to have_many(:prometheus_alert_events) }
    it { is_expected.to have_many(:related_issues) }
    it { is_expected.to have_many(:alert_management_alerts) }
  end

  describe 'project validations' do
    let(:environment) { build(:environment, project: project) }
    let(:metric) { build(:prometheus_metric, project: project) }

    subject do
      build(:prometheus_alert, prometheus_metric: metric, environment: environment, project: project)
    end

    it { is_expected.to validate_presence_of(:environment) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:prometheus_metric) }
    it { is_expected.to validate_presence_of(:operator) }
    it { is_expected.to validate_presence_of(:threshold) }

    context 'when environment and metric belongs same project' do
      it { is_expected.to be_valid }
    end

    context 'when environment belongs to different project' do
      let(:environment) { build(:environment) }

      it { is_expected.not_to be_valid }
    end

    context 'when metric belongs to different project' do
      let(:metric) { build(:prometheus_metric) }

      it { is_expected.not_to be_valid }
    end

    context 'when metric is common' do
      let(:metric) { build(:prometheus_metric, :common) }

      it { is_expected.to be_valid }
    end
  end

  describe 'runbook validations' do
    it 'disallow invalid urls' do
      unsafe_url = %{https://replaceme.com/'><script>alert(document.cookie)</script>}
      non_ascii_url = 'http://gitlab.com/user/project1/wiki/something€'
      excessively_long_url = 'https://gitla' + 'b' * 1024 + '.com'

      is_expected.not_to allow_values(
        unsafe_url,
        non_ascii_url,
        excessively_long_url
      ).for(:runbook_url)
    end

    it 'allow valid urls' do
      external_url = 'http://runbook.gitlab.com/'
      internal_url = 'http://192.168.1.1'
      blank_url = ''
      nil_url = nil

      is_expected.to allow_value(
        external_url,
        internal_url,
        blank_url,
        nil_url
      ).for(:runbook_url)
    end
  end

  describe '#full_query' do
    before do
      subject.operator = "gt"
      subject.threshold = 1
      subject.prometheus_metric = metric
    end

    it 'returns the concatenated query' do
      expect(subject.full_query).to eq("#{metric.query} > 1.0")
    end
  end

  describe '#to_param' do
    before do
      subject.operator = "gt"
      subject.threshold = 1
      subject.prometheus_metric = metric
      subject.runbook_url = 'runbook'
    end

    it 'returns the params of the prometheus alert' do
      expect(subject.to_param).to eq(
        "alert" => metric.title,
        "expr" => "#{metric.query} > 1.0",
        "for" => "5m",
        "labels" => {
          "gitlab" => "hook",
          "gitlab_alert_id" => metric.id,
          "gitlab_prometheus_alert_id" => subject.id
        },
        "annotations" => {
          "runbook" => "runbook"
        }
      )
    end
  end
end
