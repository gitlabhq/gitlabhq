require 'spec_helper'

describe GenericCommitStatus do
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:external_url) { 'http://example.gitlab.com/status' }

  let(:generic_commit_status) do
    create(:generic_commit_status, pipeline: pipeline,
                                   target_url: external_url)
  end

  describe 'validations' do
    it { is_expected.to validate_length_of(:target_url).is_at_most(255) }
    it { is_expected.to allow_value(nil).for(:target_url) }
    it { is_expected.to allow_value('http://gitlab.com/s').for(:target_url) }
    it { is_expected.not_to allow_value('javascript:alert(1)').for(:target_url) }
  end

  describe '#context' do
    subject { generic_commit_status.context }

    before do
      generic_commit_status.context = 'my_context'
    end

    it { is_expected.to eq(generic_commit_status.name) }
  end

  describe '#tags' do
    subject { generic_commit_status.tags }

    it { is_expected.to eq([:external]) }
  end

  describe '#detailed_status' do
    let(:user) { create(:user) }
    let(:status) { generic_commit_status.detailed_status(user) }

    it 'returns detailed status object' do
      expect(status).to be_a Gitlab::Ci::Status::Success
    end

    context 'when user has ability to see datails' do
      before do
        project.add_developer(user)
      end

      it 'details path points to an external URL' do
        expect(status).to have_details
        expect(status.details_path).to eq external_url
      end
    end

    context 'when user should not see details' do
      it 'does not have details' do
        expect(status).not_to have_details
      end
    end
  end

  describe 'set_default_values' do
    before do
      generic_commit_status.context = nil
      generic_commit_status.stage = nil
      generic_commit_status.save
    end

    describe '#context' do
      subject { generic_commit_status.context }

      it { is_expected.not_to be_nil }
    end

    describe '#stage' do
      subject { generic_commit_status.stage }

      it { is_expected.not_to be_nil }
    end
  end
end
