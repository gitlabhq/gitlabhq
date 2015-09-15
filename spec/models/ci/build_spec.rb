# == Schema Information
#
# Table name: builds
#
#  id                 :integer          not null, primary key
#  project_id         :integer
#  status             :string(255)
#  finished_at        :datetime
#  trace              :text
#  created_at         :datetime
#  updated_at         :datetime
#  started_at         :datetime
#  runner_id          :integer
#  commit_id          :integer
#  coverage           :float
#  commands           :text
#  job_id             :integer
#  name               :string(255)
#  deploy             :boolean          default(FALSE)
#  options            :text
#  allow_failure      :boolean          default(FALSE), not null
#  stage              :string(255)
#  trigger_request_id :integer
#

require 'spec_helper'

describe Ci::Build do
  let(:project) { FactoryGirl.create :ci_project }
  let(:commit) { FactoryGirl.create :ci_commit, project: project }
  let(:build) { FactoryGirl.create :ci_build, commit: commit }

  it { is_expected.to belong_to(:commit) }
  it { is_expected.to validate_presence_of :status }

  it { is_expected.to respond_to :success? }
  it { is_expected.to respond_to :failed? }
  it { is_expected.to respond_to :running? }
  it { is_expected.to respond_to :pending? }
  it { is_expected.to respond_to :trace_html }

  describe :first_pending do
    let(:first) { FactoryGirl.create :ci_build, commit: commit, status: 'pending', created_at: Date.yesterday }
    let(:second) { FactoryGirl.create :ci_build, commit: commit, status: 'pending' }
    before { first; second }
    subject { Ci::Build.first_pending }

    it { is_expected.to be_a(Ci::Build) }
    it('returns with the first pending build') { is_expected.to eq(first) }
  end

  describe :create_from do
    before do
      build.status = 'success'
      build.save
    end
    let(:create_from_build) { Ci::Build.create_from build }

    it 'there should be a pending task' do
      expect(Ci::Build.pending.count(:all)).to eq 0
      create_from_build
      expect(Ci::Build.pending.count(:all)).to be > 0
    end
  end

  describe :started? do
    subject { build.started? }

    context 'without started_at' do
      before { build.started_at = nil }

      it { is_expected.to be_falsey }
    end

    %w(running success failed).each do |status|
      context "if build status is #{status}" do
        before { build.status = status }

        it { is_expected.to be_truthy }
      end
    end

    %w(pending canceled).each do |status|
      context "if build status is #{status}" do
        before { build.status = status }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe :active? do
    subject { build.active? }

    %w(pending running).each do |state|
      context "if build.status is #{state}" do
        before { build.status = state }

        it { is_expected.to be_truthy }
      end
    end

    %w(success failed canceled).each do |state|
      context "if build.status is #{state}" do
        before { build.status = state }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe :complete? do
    subject { build.complete? }

    %w(success failed canceled).each do |state|
      context "if build.status is #{state}" do
        before { build.status = state }

        it { is_expected.to be_truthy }
      end
    end

    %w(pending running).each do |state|
      context "if build.status is #{state}" do
        before { build.status = state }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe :ignored? do
    subject { build.ignored? }

    context 'if build is not allowed to fail' do
      before { build.allow_failure = false }

      context 'and build.status is success' do
        before { build.status = 'success' }

        it { is_expected.to be_falsey }
      end

      context 'and build.status is failed' do
        before { build.status = 'failed' }

        it { is_expected.to be_falsey }
      end
    end

    context 'if build is allowed to fail' do
      before { build.allow_failure = true }

      context 'and build.status is success' do
        before { build.status = 'success' }

        it { is_expected.to be_falsey }
      end

      context 'and build.status is failed' do
        before { build.status = 'failed' }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe :trace do
    subject { build.trace_html }

    it { is_expected.to be_empty }

    context 'if build.trace contains text' do
      let(:text) { 'example output' }
      before { build.trace = text }

      it { is_expected.to include(text) }
      it { expect(subject.length).to be >= text.length }
    end
  end

  describe :timeout do
    subject { build.timeout }

    it { is_expected.to eq(commit.project.timeout) }
  end

  describe :duration do
    subject { build.duration }

    it { is_expected.to eq(120.0) }

    context 'if the building process has not started yet' do
      before do
        build.started_at = nil
        build.finished_at = nil
      end

      it { is_expected.to be_nil }
    end

    context 'if the building process has started' do
      before do
        build.started_at = Time.now - 1.minute
        build.finished_at = nil
      end

      it { is_expected.to be_a(Float) }
      it { is_expected.to be > 0.0 }
    end
  end

  describe :options do
    let(:options) do
      {
        image: "ruby:2.1",
        services: [
          "postgres"
        ]
      }
    end

    subject { build.options }
    it { is_expected.to eq(options) }
  end

  describe :ref do
    subject { build.ref }

    it { is_expected.to eq(commit.ref) }
  end

  describe :sha do
    subject { build.sha }

    it { is_expected.to eq(commit.sha) }
  end

  describe :short_sha do
    subject { build.short_sha }

    it { is_expected.to eq(commit.short_sha) }
  end

  describe :before_sha do
    subject { build.before_sha }

    it { is_expected.to eq(commit.before_sha) }
  end

  describe :allow_git_fetch do
    subject { build.allow_git_fetch }

    it { is_expected.to eq(project.allow_git_fetch) }
  end

  describe :project do
    subject { build.project }

    it { is_expected.to eq(commit.project) }
  end

  describe :project_id do
    subject { build.project_id }

    it { is_expected.to eq(commit.project_id) }
  end

  describe :project_name do
    subject { build.project_name }

    it { is_expected.to eq(project.name) }
  end

  describe :repo_url do
    subject { build.repo_url }

    it { is_expected.to eq(project.repo_url_with_auth) }
  end

  describe :extract_coverage do
    context 'valid content & regex' do
      subject { build.extract_coverage('Coverage 1033 / 1051 LOC (98.29%) covered', '\(\d+.\d+\%\) covered') }

      it { is_expected.to eq(98.29) }
    end

    context 'valid content & bad regex' do
      subject { build.extract_coverage('Coverage 1033 / 1051 LOC (98.29%) covered', 'very covered') }

      it { is_expected.to be_nil }
    end

    context 'no coverage content & regex' do
      subject { build.extract_coverage('No coverage for today :sad:', '\(\d+.\d+\%\) covered') }

      it { is_expected.to be_nil }
    end

    context 'multiple results in content & regex' do
      subject { build.extract_coverage(' (98.39%) covered. (98.29%) covered', '\(\d+.\d+\%\) covered') }

      it { is_expected.to eq(98.29) }
    end
  end

  describe :variables do
    context 'returns variables' do
      subject { build.variables }

      let(:variables) do
        [
          { key: :DB_NAME, value: 'postgres', public: true }
        ]
      end

      it { is_expected.to eq(variables) }

      context 'and secure variables' do
        let(:secure_variables) do
          [
            { key: 'SECRET_KEY', value: 'secret_value', public: false }
          ]
        end

        before do
          build.project.variables << Ci::Variable.new(key: 'SECRET_KEY', value: 'secret_value')
        end

        it { is_expected.to eq(variables + secure_variables) }

        context 'and trigger variables' do
          let(:trigger) { FactoryGirl.create :ci_trigger, project: project }
          let(:trigger_request) { FactoryGirl.create :ci_trigger_request_with_variables, commit: commit, trigger: trigger }
          let(:trigger_variables) do
            [
              { key: :TRIGGER_KEY, value: 'TRIGGER_VALUE', public: false }
            ]
          end

          before do
            build.trigger_request = trigger_request
          end

          it { is_expected.to eq(variables + secure_variables + trigger_variables) }
        end
      end
    end
  end
end
