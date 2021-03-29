# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Feature::Gitaly do
  let_it_be(:project) { create(:project) }
  let_it_be(:project_2) { create(:project) }

  before do
    skip_feature_flags_yaml_validation
  end

  describe ".enabled?" do
    context 'when the flag is set globally' do
      let(:feature_flag) { 'global_flag' }

      context 'when the gate is closed' do
        before do
          stub_feature_flags(gitaly_global_flag: false)
        end

        it 'returns false' do
          expect(described_class.enabled?(feature_flag)).to be(false)
        end
      end

      context 'when the flag defaults to on' do
        it 'returns true' do
          expect(described_class.enabled?(feature_flag)).to be(true)
        end
      end
    end

    context 'when the flag is enabled for a particular project' do
      let(:feature_flag) { 'project_flag' }

      before do
        stub_feature_flags(gitaly_project_flag: project)
      end

      it 'returns true for that project' do
        expect(described_class.enabled?(feature_flag, project)).to be(true)
      end

      it 'returns false for any other project' do
        expect(described_class.enabled?(feature_flag, project_2)).to be(false)
      end

      it 'returns false when no project is passed' do
        expect(described_class.enabled?(feature_flag)).to be(false)
      end
    end
  end

  describe ".server_feature_flags" do
    before do
      stub_feature_flags(gitaly_global_flag: true, gitaly_project_flag: project, non_gitaly_flag: false)
    end

    subject { described_class.server_feature_flags }

    it 'returns a hash of flags starting with the prefix, with dashes instead of underscores' do
      expect(subject).to eq('gitaly-feature-global-flag' => 'true',
                            'gitaly-feature-project-flag' => 'false')
    end

    context 'when a project is passed' do
      it 'returns the value for the flag on the given project' do
        expect(described_class.server_feature_flags(project))
          .to eq('gitaly-feature-global-flag' => 'true',
                 'gitaly-feature-project-flag' => 'true')

        expect(described_class.server_feature_flags(project_2))
          .to eq('gitaly-feature-global-flag' => 'true',
                 'gitaly-feature-project-flag' => 'false')
      end
    end

    context 'when table does not exist' do
      before do
        allow(::Gitlab::Database).to receive(:cached_table_exists?).and_return(false)
      end

      it 'returns an empty Hash' do
        expect(subject).to eq({})
      end
    end
  end
end
