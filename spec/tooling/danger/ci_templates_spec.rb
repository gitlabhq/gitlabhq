# frozen_string_literal: true

require 'gitlab/dangerfiles/spec_helper'
require 'fast_spec_helper'
require 'rspec-parameterized'

require_relative '../../../danger/plugins/ci_templates'

RSpec.describe Tooling::Danger::CiTemplates, feature_category: :tooling do
  include_context 'with dangerfile'
  subject(:ci_templates) { fake_danger.new(helper: fake_helper) }

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }

  before do
    allow(fake_helper).to receive(:ci?).and_return(ci_env)
  end

  describe '#check!' do
    context 'when not in ci environment' do
      let(:ci_env) { false }

      it 'does not add the warnings' do
        expect(ci_templates).not_to receive(:message)
        expect(ci_templates).not_to receive(:markdown)
        expect(ci_templates).not_to receive(:warn)

        ci_templates.check!
      end
    end

    context 'when in ci environment' do
      let(:ci_env) { true }
      let(:modified_files) { %w[lib/gitlab/ci/templates/ci_template.rb] }
      let(:fake_changes) { instance_double(Gitlab::Dangerfiles::Changes, files: modified_files) }

      context 'when there are updates to the ci templates' do
        before do
          allow(fake_changes).to receive(:by_category).with(:ci_template).and_return(fake_changes)
          allow(fake_helper).to receive(:changes).and_return(fake_changes)
          allow(ci_templates).to receive(:message)
          allow(ci_templates).to receive(:markdown)
          allow(fake_helper).to receive(:markdown_list).and_return(modified_files)
        end

        it 'adds the danger message, markdown and warning' do
          expect(ci_templates).to receive(:message)
          expect(ci_templates).to receive(:markdown)
          expect(ci_templates).to receive(:warn)

          ci_templates.check!
        end

        context 'when there are files returned by markdown_list' do
          it 'returns markdown message' do
            expect(fake_helper).to receive(:markdown_list).with(modified_files)
            expect(ci_templates).to receive(:markdown).with(/#{modified_files}/)

            ci_templates.check!
          end
        end
      end

      context 'when there are no updated ci templates' do
        it 'does not add the danger message, markdown and warning' do
          expect(ci_templates).not_to receive(:message)
          expect(ci_templates).not_to receive(:markdown)
          expect(ci_templates).not_to receive(:warn)

          ci_templates.check!
        end
      end
    end
  end
end
