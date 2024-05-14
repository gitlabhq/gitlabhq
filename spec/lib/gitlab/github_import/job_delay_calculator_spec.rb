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

    before do
      stub_application_setting(concurrent_github_import_jobs_limit: 10)
    end

    it { is_expected.to eq({ size: 10, delay: 1.minute }) }
  end
end
