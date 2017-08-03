require 'spec_helper'

describe ::Gitlab::GlRepository do
  describe '.parse' do
    set(:project) { create(:project, :repository) }

    it 'parses a project gl_repository' do
      expect(described_class.parse("project-#{project.id}")).to eq([project, false])
    end

    it 'parses a wiki gl_repository' do
      expect(described_class.parse("wiki-#{project.id}")).to eq([project, true])
    end

    it 'throws an argument error on an invalid gl_repository' do
      expect { described_class.parse("badformat-#{project.id}") }.to raise_error(ArgumentError)
    end
  end
end
