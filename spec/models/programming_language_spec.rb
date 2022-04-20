# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProgrammingLanguage do
  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:color) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to allow_value("#000000").for(:color) }
  it { is_expected.not_to allow_value("000000").for(:color) }
  it { is_expected.not_to allow_value("#0z0000").for(:color) }

  describe '.with_name_case_insensitive scope' do
    let_it_be(:ruby) { create(:programming_language, name: 'Ruby') }
    let_it_be(:python) { create(:programming_language, name: 'Python') }
    let_it_be(:swift) { create(:programming_language, name: 'Swift') }

    it 'accepts a single name parameter' do
      expect(described_class.with_name_case_insensitive('swift')).to(
        contain_exactly(swift)
      )
    end

    it 'accepts multiple names' do
      expect(described_class.with_name_case_insensitive('ruby', 'python')).to(
        contain_exactly(ruby, python)
      )
    end
  end
end
