# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:db:decomposition:connection_status', feature_category: :cell do
  let(:max_connections) { 500 }
  let(:current_connections) { 300 }

  subject { run_rake_task('gitlab:db:decomposition:connection_status') }

  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/db/decomposition/connection_status'
  end

  before do
    allow(ApplicationRecord.connection).to receive(:select_one).with(any_args).and_return(
      { "active" => current_connections, "max" => max_connections }
    )
  end

  context 'when separate ci database is not configured' do
    before do
      skip_if_multiple_databases_are_setup
    end

    context "when PostgreSQL max_connections is too low" do
      it 'suggests to increase it' do
        expect { subject }.to output(
          "Currently using #{current_connections} connections out of #{max_connections} max_connections,\n" \
          "which may run out when you switch to two database connections.\n\n" \
          "Consider increasing PostgreSQL 'max_connections' setting.\n" \
          "Depending on the installation method, there are different ways to\n" \
          "increase that setting. Please consult the GitLab documentation.\n"
        ).to_stdout
      end
    end

    context "when PostgreSQL max_connections is high enough" do
      let(:max_connections) { 1000 }

      it 'only shows current status' do
        expect { subject }.to output(
          "Currently using #{current_connections} connections out of #{max_connections} max_connections,\n" \
          "which is enough for running GitLab using two database connections.\n"
        ).to_stdout
      end
    end
  end

  context 'when separate ci database is configured' do
    before do
      skip_if_multiple_databases_not_setup(:ci)
    end

    it "does not show connection information" do
      expect { subject }.to output(
        "GitLab database already running on two connections\n"
      ).to_stdout
    end
  end
end
