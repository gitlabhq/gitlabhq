# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SampleDataTemplate do
  describe '.all' do
    it 'returns all templates' do
      expected = %w[
        sample
      ]

      expect(described_class.all).to be_an(Array)
      expect(described_class.all.map(&:name)).to match_array(expected)
    end
  end

  describe '.find' do
    subject { described_class.find(query) }

    context 'when there is a match' do
      let(:query) { :sample }

      it { is_expected.to be_a(described_class) }
    end

    context 'when there is no match' do
      let(:query) { 'no-match' }

      it { is_expected.to be(nil) }
    end
  end

  describe '.archive_directory' do
    subject { described_class.archive_directory }

    it { is_expected.to be_a Pathname }
  end

  describe 'validate all templates' do
    let_it_be(:admin) { create(:admin) }

    described_class.all.each do |template|
      it "#{template.name} has a valid archive" do
        archive = template.archive_path

        expect(File.exist?(archive)).to be(true)
      end

      context 'with valid parameters' do
        it 'can be imported' do
          params = {
            template_name: template.name,
            namespace_id: admin.namespace.id,
            path: template.name
          }

          project = Projects::CreateFromTemplateService.new(admin, params).execute

          expect(project).to be_valid
          expect(project).to be_persisted
        end
      end
    end
  end
end
