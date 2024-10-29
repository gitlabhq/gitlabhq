# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::LegacyGithubImport::IssuableFormatter do
  let(:raw_data) do
    { number: 42 }
  end

  let(:project) { double(import_type: 'github') }
  let(:issuable_formatter) { described_class.new(project, raw_data) }

  describe '#project_association' do
    it { expect { issuable_formatter.project_association }.to raise_error(NotImplementedError) }
  end

  describe '#project_assignee_association' do
    it { expect { issuable_formatter.project_assignee_association }.to raise_error(NotImplementedError) }
  end

  describe '#number' do
    it { expect(issuable_formatter.number).to eq(42) }
  end

  describe '#find_condition' do
    it { expect(issuable_formatter.find_condition).to eq({ iid: 42 }) }
  end

  describe '#contributing_assignee_formatters' do
    it { expect { issuable_formatter.contributing_assignee_formatters }.to raise_error(NotImplementedError) }
  end
end
