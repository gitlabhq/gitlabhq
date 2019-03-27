# frozen_string_literal: true

describe Gitlab::Danger::Teammate do
  subject { described_class.new({ 'projects' => projects }) }
  let(:projects) { { project => capabilities } }
  let(:project) { double }

  describe 'multiple roles project project' do
    let(:capabilities) { ['reviewer backend', 'maintainer frontend', 'trainee_maintainer database'] }

    it '#reviewer? supports multiple roles per project' do
      expect(subject.reviewer?(project, 'backend')).to be_truthy
    end

    it '#traintainer? supports multiple roles per project' do
      expect(subject.traintainer?(project, 'database')).to be_truthy
    end

    it '#maintainer? supports multiple roles per project' do
      expect(subject.maintainer?(project, 'frontend')).to be_truthy
    end
  end

  describe 'one role project project' do
    let(:capabilities) { 'reviewer backend' }

    it '#reviewer? supports one role per project' do
      expect(subject.reviewer?(project, 'backend')).to be_truthy
    end

    it '#traintainer? supports one role per project' do
      expect(subject.traintainer?(project, 'database')).to be_falsey
    end

    it '#maintainer? supports one role per project' do
      expect(subject.maintainer?(project, 'frontend')).to be_falsey
    end
  end
end
