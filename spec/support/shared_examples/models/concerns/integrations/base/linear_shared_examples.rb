# frozen_string_literal: true

RSpec.shared_examples Integrations::Base::Linear do
  it_behaves_like Integrations::HasAvatar

  describe 'Validations' do
    context 'when integration is active' do
      before do
        subject.activate!
      end

      it { is_expected.to validate_presence_of(:workspace_url) }

      it { is_expected.to allow_value("https://linear.app/test").for(:workspace_url) }

      it { is_expected.not_to allow_value("linear.app/test").for(:workspace_url) }
      it { is_expected.not_to allow_value("https://linear.app/test/bar/baz").for(:workspace_url) }
      it { is_expected.not_to allow_value('https://example.com').for(:workspace_url) }
      it { is_expected.not_to allow_value('example.com').for(:workspace_url) }
      it { is_expected.not_to allow_value('ftp://example.com').for(:workspace_url) }
      it { is_expected.not_to allow_value('herp-and-derp').for(:workspace_url) }
    end

    context 'when integration is inactive' do
      before do
        subject.deactivate!
      end

      it { is_expected.not_to validate_presence_of(:workspace_url) }
    end
  end

  describe '#reference_pattern' do
    it 'matches full issue reference (team prefix + id)' do
      expect(subject.reference_pattern.match('PRJ-123')[:issue]).to eq('PRJ-123')
      expect(subject.reference_pattern.match('123-123')[:issue]).to eq('123-123')
      expect(subject.reference_pattern.match('ABCDEFG-123')[:issue]).to eq('ABCDEFG-123')
    end

    it 'does not match invalid references' do
      # too long
      expect(subject.reference_pattern.match('12345678-123')).to be_nil
      # no dash
      expect(subject.reference_pattern.match('ABCD1234')).to be_nil
      # other leading characters
      expect(subject.reference_pattern.match('abcABC-123')).to be_nil
      # other following characters
      expect(subject.reference_pattern.match('ABC-123abc')).to be_nil
    end
  end

  describe '#project_url' do
    before do
      subject.workspace_url = 'https://linear.app/test'
    end

    it 'returns the project URL' do
      expect(subject.project_url).to eq('https://linear.app/test')
    end
  end

  describe '#issue_url' do
    before do
      subject.workspace_url = 'https://linear.app/test'
    end

    it 'returns the project URL' do
      expect(subject.issue_url('PRJ-123')).to eq('https://linear.app/test/issue/PRJ-123')
    end
  end

  describe '#fields' do
    it 'only returns the workspace_url field' do
      expect(subject.fields.pluck(:name)).to eq(%w[workspace_url])
    end
  end

  describe '#supports_data_fields?' do
    it 'returns false' do
      expect(subject.supports_data_fields?).to be(false)
    end
  end
end
