# frozen_string_literal: true

RSpec.shared_examples Integrations::Base::Phorge do
  it_behaves_like Integrations::HasAvatar

  describe 'Validations' do
    subject { build(:phorge_integration, active: active) }

    context 'when integration is active' do
      let(:active) { true }

      it { is_expected.to validate_presence_of(:project_url) }
      it { is_expected.to validate_presence_of(:issues_url) }

      it_behaves_like 'issue tracker integration URL attribute', :project_url
      it_behaves_like 'issue tracker integration URL attribute', :issues_url
    end

    context 'when integration is inactive' do
      let(:active) { false }

      it { is_expected.not_to validate_presence_of(:project_url) }
      it { is_expected.not_to validate_presence_of(:issues_url) }
    end
  end

  describe '#issues_url normalization' do
    it 'strips the redundant task prefix in front of the :id placeholder' do
      integration = build(:phorge_integration, issues_url: 'https://phorge.example.com/T:id')

      integration.valid?

      expect(integration.issues_url).to eq('https://phorge.example.com/:id')
      expect(integration.issue_url('T123')).to eq('https://phorge.example.com/T123')
    end

    it 'leaves an issues URL with a plain :id placeholder untouched' do
      integration = build(:phorge_integration, issues_url: 'https://phorge.example.com/:id')

      integration.valid?

      expect(integration.issues_url).to eq('https://phorge.example.com/:id')
    end

    it 'leaves an issues URL without a placeholder untouched' do
      integration = build(:phorge_integration, issues_url: 'https://phorge.example.com/tasks')

      integration.valid?

      expect(integration.issues_url).to eq('https://phorge.example.com/tasks')
    end

    # A lowercase t is far more likely to end a path segment than to be a mistyped
    # prefix, so stripping it would break URLs that are already correct.
    it 'leaves a lowercase t in front of the :id placeholder untouched' do
      integration = build(:phorge_integration, issues_url: 'https://phorge.example.com/t:id')

      integration.valid?

      expect(integration.issues_url).to eq('https://phorge.example.com/t:id')
    end
  end

  describe '#reference_pattern' do
    using RSpec::Parameterized::TableSyntax

    let(:reference_pattern) { build(:phorge_integration).reference_pattern }

    subject { reference_pattern }

    context 'when text contains a Phorge Maniphest task reference' do
      where(:text, :reference) do
        'Referencing T111' | 'T111'
        'Referencing T222, mid sentence' | 'T222'
        'Referencing (T333) in parentheses' | 'T333'
        'Referencing #T444 with a hash prefix' | 'T444'
      end

      with_them do
        it { is_expected.to match(text) }

        it 'captures the task reference' do
          expect(reference_pattern.match(text)[:issue]).to eq(reference)
        end
      end
    end

    context 'when text contains something resembling but is not a Phorge Maniphest task reference' do
      where(:text) do
        [
          'See docs for Model-T1',
          'cc user @T1'
        ]
      end

      with_them do
        it { is_expected.not_to match(text) }
      end
    end
  end
end
