# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::JobDelayCalculator, feature_category: :importers do
  let(:project) { build(:project) }

  let(:importer_class) do
    Class.new do
      attr_reader :project

      def initialize(project)
        @project = project
      end

      include Gitlab::GithubImport::JobDelayCalculator
    end
  end

  describe "#parallel_import_batch" do
    subject { importer_class.new(project).parallel_import_batch }

    it { is_expected.to eq({ size: 5000, delay: 1.minute }) }

    context 'when `github_import_increased_concurrent_workers` feature flag is disabled' do
      before do
        stub_feature_flags(github_import_increased_concurrent_workers: false)
      end

      it { is_expected.to eq({ size: 1000, delay: 1.minute }) }
    end
  end
end
