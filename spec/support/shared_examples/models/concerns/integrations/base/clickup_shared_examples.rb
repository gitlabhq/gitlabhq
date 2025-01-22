# frozen_string_literal: true

RSpec.shared_examples Integrations::Base::Clickup do
  it_behaves_like Integrations::HasAvatar

  describe 'Validations' do
    context 'when integration is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:project_url) }
      it { is_expected.to validate_presence_of(:issues_url) }

      it_behaves_like 'issue tracker integration URL attribute', :project_url
      it_behaves_like 'issue tracker integration URL attribute', :issues_url
    end

    context 'when integration is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:project_url) }
      it { is_expected.not_to validate_presence_of(:issues_url) }
    end
  end

  describe '#reference_pattern' do
    it 'does allow project prefix on the reference' do
      expect(subject.reference_pattern.match('PRJ-123')[:issue]).to eq('PRJ-123')
    end

    it 'allows a hash with an alphanumeric key on the reference' do
      expect(subject.reference_pattern.match('#abcd123')[:issue]).to eq('abcd123')
    end

    it 'allows a global prefix with an alphanumeric key on the reference' do
      expect(subject.reference_pattern.match('CU-abcd123')[:issue]).to eq('abcd123')
    end
  end

  describe '#fields' do
    it 'only returns the project_url and issues_url fields' do
      expect(subject.fields.pluck(:name)).to eq(%w[project_url issues_url])
    end
  end
end
