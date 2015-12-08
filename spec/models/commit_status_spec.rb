# == Schema Information
#
# Table name: ci_builds
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
#  coverage           :float
#  commit_id          :integer
#  commands           :text
#  job_id             :integer
#  name               :string(255)
#  deploy             :boolean          default(FALSE)
#  options            :text
#  allow_failure      :boolean          default(FALSE), not null
#  stage              :string(255)
#  trigger_request_id :integer
#  stage_idx          :integer
#  tag                :boolean
#  ref                :string(255)
#  user_id            :integer
#  type               :string(255)
#  target_url         :string(255)
#  description        :string(255)
#  artifacts_file     :text
#

require 'spec_helper'

describe CommitStatus do
  let(:commit) { FactoryGirl.create :ci_commit }
  let(:commit_status) { FactoryGirl.create :commit_status, commit: commit }

  it { is_expected.to belong_to(:commit) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_inclusion_of(:status).in_array(%w(pending running failed success canceled)) }

  it { is_expected.to delegate_method(:sha).to(:commit) }
  it { is_expected.to delegate_method(:short_sha).to(:commit) }
  it { is_expected.to delegate_method(:gl_project).to(:commit) }
  
  it { is_expected.to respond_to :success? }
  it { is_expected.to respond_to :failed? }
  it { is_expected.to respond_to :running? }
  it { is_expected.to respond_to :pending? }

  describe :author do
    subject { commit_status.author }
    before { commit_status.author = User.new }

    it { is_expected.to eq(commit_status.user) }
  end

  describe :started? do
    subject { commit_status.started? }

    context 'without started_at' do
      before { commit_status.started_at = nil }

      it { is_expected.to be_falsey }
    end

    %w(running success failed).each do |status|
      context "if commit status is #{status}" do
        before { commit_status.status = status }

        it { is_expected.to be_truthy }
      end
    end

    %w(pending canceled).each do |status|
      context "if commit status is #{status}" do
        before { commit_status.status = status }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe :active? do
    subject { commit_status.active? }

    %w(pending running).each do |state|
      context "if commit_status.status is #{state}" do
        before { commit_status.status = state }

        it { is_expected.to be_truthy }
      end
    end

    %w(success failed canceled).each do |state|
      context "if commit_status.status is #{state}" do
        before { commit_status.status = state }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe :complete? do
    subject { commit_status.complete? }

    %w(success failed canceled).each do |state|
      context "if commit_status.status is #{state}" do
        before { commit_status.status = state }

        it { is_expected.to be_truthy }
      end
    end

    %w(pending running).each do |state|
      context "if commit_status.status is #{state}" do
        before { commit_status.status = state }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe :duration do
    subject { commit_status.duration }

    it { is_expected.to eq(120.0) }

    context 'if the building process has not started yet' do
      before do
        commit_status.started_at = nil
        commit_status.finished_at = nil
      end

      it { is_expected.to be_nil }
    end

    context 'if the building process has started' do
      before do
        commit_status.started_at = Time.now - 1.minute
        commit_status.finished_at = nil
      end

      it { is_expected.to be_a(Float) }
      it { is_expected.to be > 0.0 }
    end
  end
  
  describe :latest do
    subject { CommitStatus.latest.order(:id) }

    before do
      @commit1 = FactoryGirl.create :commit_status, commit: commit, name: 'aa', ref: 'bb', status: 'running'
      @commit2 = FactoryGirl.create :commit_status, commit: commit, name: 'cc', ref: 'cc', status: 'pending'
      @commit3 = FactoryGirl.create :commit_status, commit: commit, name: 'aa', ref: 'cc', status: 'success'
      @commit4 = FactoryGirl.create :commit_status, commit: commit, name: 'cc', ref: 'bb', status: 'success'
      @commit5 = FactoryGirl.create :commit_status, commit: commit, name: 'aa', ref: 'bb', status: 'success'
    end

    it 'return unique statuses' do
      is_expected.to eq([@commit2, @commit3, @commit4, @commit5])
    end
  end

  describe :for_ref do
    subject { CommitStatus.for_ref('bb').order(:id) }

    before do
      @commit1 = FactoryGirl.create :commit_status, commit: commit, name: 'aa', ref: 'bb', status: 'running'
      @commit2 = FactoryGirl.create :commit_status, commit: commit, name: 'cc', ref: 'cc', status: 'pending'
      @commit3 = FactoryGirl.create :commit_status, commit: commit, name: 'aa', ref: nil, status: 'success'
    end

    it 'return statuses with equal and nil ref set' do
      is_expected.to eq([@commit1])
    end
  end

  describe :running_or_pending do
    subject { CommitStatus.running_or_pending.order(:id) }

    before do
      @commit1 = FactoryGirl.create :commit_status, commit: commit, name: 'aa', ref: 'bb', status: 'running'
      @commit2 = FactoryGirl.create :commit_status, commit: commit, name: 'cc', ref: 'cc', status: 'pending'
      @commit3 = FactoryGirl.create :commit_status, commit: commit, name: 'aa', ref: nil, status: 'success'
      @commit4 = FactoryGirl.create :commit_status, commit: commit, name: 'dd', ref: nil, status: 'failed'
      @commit5 = FactoryGirl.create :commit_status, commit: commit, name: 'ee', ref: nil, status: 'canceled'
    end

    it 'return statuses that are running or pending' do
      is_expected.to eq([@commit1, @commit2])
    end
  end
end
