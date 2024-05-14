# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/rubocop_new_todo'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::RubocopNewTodo, feature_category: :tooling do
  include_context "with dangerfile"

  let(:filename) { 'spec/foo_spec.rb' }
  let(:fake_danger) { DangerSpecHelper.fake_danger }
  let(:fake_project_helper) { instance_double('Tooling::Danger::ProjectHelper') }
  let(:context) { fake_danger.new(helper: fake_helper) }

  let(:template) { described_class::SUGGESTION }

  let(:file_lines) do
    <<~RUBY.split("\n")
      ---
      A/Rule/Name:
        Details: grace period
        Exclude:
          - 'foo_spec.rb'
    RUBY
  end

  let(:changed_lines) { file_lines.map { |line| "+#{line}" } }

  subject(:new_todo) { described_class.new(filename, context: context) }

  before do
    allow(context).to receive(:project_helper).and_return(fake_project_helper)
    allow(context.helper).to receive(:changed_lines).with(filename).and_return(changed_lines)
    allow(context.project_helper).to receive(:file_lines).and_return(file_lines)
  end

  it 'adds comment once' do
    expect(context).to receive(:markdown).with("\n#{template}".chomp, file: filename, line: 2)

    new_todo.suggest
  end
end
