# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/internal_users'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::InternalUsers, feature_category: :tooling do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:fake_project_helper) { instance_double(Tooling::Danger::ProjectHelper) }
  let(:file_path) { 'app/models/user.rb' }
  let(:changed_lines) { [] }
  let(:file_lines) { [] }

  subject(:helper) { fake_danger.new(helper: fake_helper) }

  before do
    allow(helper).to receive(:project_helper).and_return(fake_project_helper)
    allow(fake_helper).to receive(:all_changed_files).and_return([file_path])
    allow(fake_helper).to receive(:changed_lines).with(file_path).and_return(changed_lines)
    allow(fake_project_helper).to receive(:file_lines).with(file_path).and_return(file_lines)
  end

  describe '#add_comment_for_internal_users_changes' do
    shared_examples 'no violations' do
      it 'adds no comments' do
        expect(helper).not_to receive(:markdown)
        expect(helper).not_to receive(:warn)

        helper.add_comment_for_internal_users_changes
      end
    end

    shared_examples 'has violations' do
      it 'adds file and MR level comments' do
        expect(helper).to receive(:markdown).once
        expect(helper).to receive(:warn).once

        helper.add_comment_for_internal_users_changes
      end
    end

    context 'when documentation is changed' do
      before do
        allow(fake_helper).to receive(:all_changed_files).and_return([described_class::DOCS_PATH])
      end

      include_examples 'no violations'
    end

    context 'when method name is changed' do
      let(:changed_lines) do
        [
          '-  def security_bot',
          '+  def security_bot_v2'
        ]
      end

      let(:file_lines) { ['  def security_bot_v2'] }

      include_examples 'has violations'
    end

    context 'when method body is changed' do
      let(:changed_lines) do
        [
          '  def security_bot',
          '+    super',
          '  end'
        ]
      end

      let(:file_lines) do
        [
          'def security_bot',
          '  super',
          'end'
        ]
      end

      include_examples 'has violations'
    end

    context 'when bot module is referenced' do
      let(:changed_lines) do
        [
          '+    Users::Internal.security_bot'
        ]
      end

      let(:file_lines) { ['    Users::Internal.security_bot'] }

      include_examples 'has violations'
    end

    context 'when bot symbol is used' do
      let(:changed_lines) do
        [
          '+    user_type: :security_bot'
        ]
      end

      let(:file_lines) { ['    user_type: :security_bot'] }

      include_examples 'has violations'
    end

    context 'when changes are unrelated' do
      let(:changed_lines) do
        [
          '+    user.name = "Regular User"'
        ]
      end

      let(:file_lines) { ['    user.name = "Regular User"'] }

      include_examples 'no violations'
    end

    context 'when changing lines inside a bot method definition' do
      let(:changed_lines) do
        [
          '    user.name = "Bot Name"'
        ]
      end

      let(:file_lines) do
        [
          'def security_bot',
          '    user.name = "Bot Name"',
          'end'
        ]
      end

      include_examples 'has violations'
    end

    context 'when changing lines outside any bot method definition' do
      let(:changed_lines) do
        [
          '    user.name = "Regular Name"'
        ]
      end

      let(:file_lines) do
        [
          'def regular_method',
          '    user.name = "Regular Name"',
          'end'
        ]
      end

      include_examples 'no violations'
    end

    context 'when bot method spans multiple ends' do
      let(:changed_lines) do
        [
          '    user.tap do |u|',
          '      u.name = "Bot Name"',
          '    end'
        ]
      end

      let(:file_lines) do
        [
          'def security_bot',
          '    user.tap do |u|',
          '      u.name = "Bot Name"',
          '    end',
          'end'
        ]
      end

      include_examples 'has violations'
    end

    context 'when modifying code between bot methods' do
      let(:changed_lines) do
        [
          '    user.name = "Regular Name"'
        ]
      end

      let(:file_lines) do
        [
          'def security_bot',
          '  # bot code',
          'end',
          '    user.name = "Regular Name"',
          'def alert_bot',
          '  # bot code',
          'end'
        ]
      end

      include_examples 'no violations'
    end

    context 'when file is not a ruby file' do
      let(:file_path) { 'some_file.png' }
      let(:changed_lines) { [] }

      include_examples 'no violations'
    end
  end

  describe '#file_has_violations?' do
    context 'when tracking bot method boundaries' do
      let(:changed_lines) { ['  some_code'] }

      it 'correctly tracks entering and exiting bot methods' do
        allow(fake_project_helper).to receive(:file_lines).and_return([
          'def security_bot',
          '  some_code',
          'end'
        ])

        expect(helper.send(:file_has_violations?, file_path)).to be true

        allow(fake_project_helper).to receive(:file_lines).and_return([
          'def security_bot',
          '  other_code',
          'end',
          '  some_code'
        ])

        expect(helper.send(:file_has_violations?, file_path)).to be false
      end

      it 'handles nested end keywords' do
        allow(fake_project_helper).to receive(:file_lines).and_return([
          'def security_bot',
          '  some_code',
          '  if true',
          '    some_code',
          '  end',
          'end'
        ])

        expect(helper.send(:file_has_violations?, file_path)).to be true
      end

      it 'processes all lines in method body' do
        lines = [
          'def security_bot',
          '  line1',
          '  line2',
          '  line3',
          'end'
        ]

        allow(fake_project_helper).to receive(:file_lines).and_return(lines)
        allow(fake_helper).to receive(:changed_lines).and_return(['  line2'])

        expect(helper.send(:file_has_violations?, file_path)).to be true
      end
    end
  end
end
