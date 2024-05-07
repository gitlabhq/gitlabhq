# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Phorge, feature_category: :integrations do
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
