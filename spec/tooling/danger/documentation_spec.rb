# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'
require_relative '../../../tooling/danger/documentation'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::Documentation, feature_category: :markdown do
  include_context "with dangerfile"

  subject(:documentation) { fake_danger.new(helper: fake_helper) }

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:mr_labels) { [] }
  let(:labels_to_add) { [] }
  let(:existing_scoped_label_scopes) { [] }

  before do
    allow(fake_helper).to receive_messages(
      changes_by_category: { docs:, mr_labels: },
      labels_to_add: labels_to_add
    )
    allow(fake_helper).to receive(:has_scoped_label_with_scope?) do |scope|
      existing_scoped_label_scopes.include?(scope)
    end
    allow(documentation).to receive(:message)
    allow(documentation).to receive(:markdown)
  end

  describe '#check_documentation' do
    subject(:check_documentation) { documentation.check_documentation }

    shared_examples_for "doesn't warn" do
      it 'does not add a warning' do
        expect(documentation).not_to receive(:warn)
        check_documentation
      end
    end

    shared_examples_for "doesn't message" do
      it 'does not add a message' do
        expect(documentation).not_to receive(:message)
        check_documentation
      end
    end

    shared_examples_for "doesn't add labels" do
      it 'does not add labels' do
        check_documentation
        expect(labels_to_add).to be_empty
      end
    end

    shared_examples_for "doesn't add markdown" do
      it 'does not add markdown' do
        expect(documentation).not_to receive(:markdown)
        check_documentation
      end
    end

    shared_examples_for 'warns' do |warning|
      it 'adds a warning' do
        expect(documentation).to receive(:warn).with(warning)
        expect(documentation).not_to receive(:message)
        expect(documentation).not_to receive(:markdown)
        check_documentation
      end
    end

    shared_examples_for 'adds messages' do |*expectations|
      it 'adds a message' do
        expect(documentation).not_to receive(:warn)
        messages = []
        expect(documentation).to receive(:message) do |actual, *_|
          messages << actual
        end
        check_documentation
        messages.zip(expectations) do |actual, expected|
          expect(actual).to match(expected)
        end
      end
    end

    shared_examples_for 'adds labels' do |labels|
      it "adds labels #{labels.join(', ')}" do
        check_documentation
        expect(labels_to_add.uniq).to match_array(labels)
      end
    end

    shared_examples_for 'adds markdown' do |markdown|
      it "adds #{markdown.inspect} to markdown" do
        expect(documentation).to receive(:markdown).with(markdown)
        check_documentation
      end
    end

    context 'when there are no documentation changes' do
      let(:docs) { [] }

      it_behaves_like "doesn't warn"
      it_behaves_like "doesn't message"
      it_behaves_like "doesn't add labels"
      it_behaves_like "doesn't add markdown"
    end

    context 'when there are no documentation changes on a feature MR' do
      let(:docs) { [] }
      let(:mr_labels) { %w[feature::addition] }

      it_behaves_like 'warns', described_class::DOCUMENTATION_UPDATE_MISSING
      it_behaves_like "doesn't message"
      it_behaves_like "doesn't add labels"
      it_behaves_like "doesn't add markdown"
    end

    context 'when there are development docs changes' do
      let(:docs) { ['doc/development/logs.md', 'doc/development/semver.md'] }

      it_behaves_like "doesn't warn"
      it_behaves_like 'adds messages', %r{contains docs in the /doc/development directory, but any Maintainer can merge}
      it_behaves_like 'adds labels',
        ['development guidelines', 'documentation', 'type::maintenance', 'maintenance::refactor']
      it_behaves_like "doesn't add markdown"
    end

    context 'when there are solutions docs changes' do
      let(:docs) { ['doc/solutions/_index.md'] }

      it_behaves_like "doesn't warn"
      it_behaves_like 'adds messages',
        %r{contains docs in the /doc/solutions directory and should be reviewed by a Solutions Architect}
      it_behaves_like 'adds labels',
        ['Solutions', 'documentation', 'type::maintenance', 'maintenance::refactor']
      it_behaves_like "doesn't add markdown"
    end

    context 'when there are localized doc changes' do
      let(:docs) { ['doc-locale/ja-jp/_index.md', 'doc-locale/ja-jp/devsecops.md'] }

      it_behaves_like "doesn't warn"
      it_behaves_like 'adds messages', %r{should not be edited directly}
      it_behaves_like "doesn't add labels"
      it_behaves_like "doesn't add markdown"
    end

    context 'when there are docs changes requiring the tier 3 pipeline' do
      let(:docs) { ['doc/api/settings.md'] }

      it_behaves_like "doesn't warn"
      it_behaves_like 'adds messages', %r{that require a tier-3 code pipeline}
      it_behaves_like "doesn't add labels"
      it_behaves_like "doesn't add markdown"
    end

    context 'when there are other docs changes' do
      let(:docs) { ['doc/user/markdown.md', 'doc/security/_index.md'] }

      it_behaves_like "doesn't warn"
      it_behaves_like 'adds messages', %r{adds or changes documentation files and requires Technical Writing review}
      it_behaves_like "doesn't add labels"
      it_behaves_like 'adds markdown',
        /#{Regexp.escape "* `doc/user/markdown.md` ([Link to current live version](https://docs.gitlab.com/user/markdown/))\n"}/
      it_behaves_like 'adds markdown',
        /#{Regexp.escape "* `doc/security/_index.md` ([Link to current live version](https://docs.gitlab.com/security/))\n"}/
    end

    context 'when there are many kinds of doc changes' do
      let(:docs) do
        ['doc/development/mcp_server.md', 'doc/solutions/cloud/_index.md', 'doc/_index.md',
          'doc/legal/developer_certificate_of_origin.md', 'doc/ci/debugging.md']
      end

      it_behaves_like "doesn't warn"
      it_behaves_like 'adds messages',
        %r{contains docs in the /doc/development directory, but any Maintainer can merge},
        %r{contains docs in the /doc/solutions directory and should be reviewed by a Solutions Architect},
        %r{that require a tier-3 code pipeline}
      it_behaves_like 'adds labels',
        ['development guidelines', 'Solutions', 'documentation', 'type::maintenance',
          'maintenance::refactor']
      it_behaves_like 'adds markdown',
        /#{Regexp.escape "* `doc/legal/developer_certificate_of_origin.md` ([Link to current live version](https://docs.gitlab.com/legal/developer_certificate_of_origin/))\n"}/
      it_behaves_like 'adds markdown',
        /#{Regexp.escape "* `doc/ci/debugging.md` ([Link to current live version](https://docs.gitlab.com/ci/debugging/))\n"}/
    end

    context 'when there are development docs changes and the MR already has a type label' do
      let(:docs) { ['doc/development/json.md'] }
      let(:existing_scoped_label_scopes) { ['type'] }

      it_behaves_like 'adds labels', ['development guidelines', 'documentation', 'maintenance::refactor']
    end
  end
end
