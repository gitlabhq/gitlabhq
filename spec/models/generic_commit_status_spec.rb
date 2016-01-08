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
#  gl_project_id      :integer
#

require 'spec_helper'

describe GenericCommitStatus, models: true do
  let(:commit) { FactoryGirl.create :ci_commit }
  let(:generic_commit_status) { FactoryGirl.create :generic_commit_status, commit: commit }

  describe :context do
    subject { generic_commit_status.context }
    before { generic_commit_status.context = 'my_context' }

    it { is_expected.to eq(generic_commit_status.name) }
  end

  describe :tags do
    subject { generic_commit_status.tags }

    it { is_expected.to eq([:external]) }
  end

  describe :set_default_values do
    before do
      generic_commit_status.context = nil
      generic_commit_status.stage = nil
      generic_commit_status.save
    end

    describe :context do
      subject { generic_commit_status.context }

      it { is_expected.to_not be_nil }
    end

    describe :stage do
      subject { generic_commit_status.stage }

      it { is_expected.to_not be_nil }
    end
  end
end
