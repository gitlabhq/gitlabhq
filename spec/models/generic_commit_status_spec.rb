# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GenericCommitStatus do
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:external_url) { 'http://example.gitlab.com/status' }

  let(:generic_commit_status) do
    create(:generic_commit_status, pipeline: pipeline, target_url: external_url)
  end

  describe 'validations' do
    it { is_expected.to validate_length_of(:target_url).is_at_most(255) }
    it { is_expected.to allow_value(nil).for(:target_url) }
    it { is_expected.to allow_value('http://gitlab.com/s').for(:target_url) }
    it { is_expected.not_to allow_value('javascript:alert(1)').for(:target_url) }
  end

  describe '#name_uniqueness_across_types' do
    let(:attributes) { { context: 'default' } }
    let(:commit_status) { described_class.new(attributes) }
    let(:status_name) { 'test-job' }

    subject(:errors) { commit_status.errors[:name] }

    shared_examples 'it does not have uniqueness errors' do
      it 'does not return errors' do
        commit_status.valid?

        is_expected.to be_empty
      end
    end

    context 'without attributes' do
      it_behaves_like 'it does not have uniqueness errors'
    end

    context 'with only a pipeline' do
      let(:attributes) { { pipeline: pipeline, context: 'default' } }

      context 'without name' do
        it_behaves_like 'it does not have uniqueness errors'
      end
    end

    context 'with only a name' do
      let(:attributes) { { name: status_name } }

      context 'without pipeline' do
        it_behaves_like 'it does not have uniqueness errors'
      end
    end

    context 'with pipeline and name' do
      let(:attributes) do
        {
          pipeline: pipeline,
          name: status_name
        }
      end

      context 'without other statuses' do
        it_behaves_like 'it does not have uniqueness errors'
      end

      context 'with generic statuses' do
        before do
          create(:generic_commit_status, pipeline: pipeline, name: status_name)
        end

        it_behaves_like 'it does not have uniqueness errors'
      end

      context 'with ci_build statuses' do
        before do
          create(:ci_build, pipeline: pipeline, name: status_name)
        end

        it 'returns name error' do
          expect(commit_status).to be_invalid
          is_expected.to include('has already been taken')
        end
      end
    end
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

  describe '#present' do
    subject { generic_commit_status.present }

    it { is_expected.to be_a(GenericCommitStatusPresenter) }
  end
end
