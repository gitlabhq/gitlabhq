# frozen_string_literal: true

RSpec.shared_examples 'projects squash option' do
  using RSpec::Parameterized::TableSyntax

  describe '#human_squash_option' do
    where(:squash_option, :human_squash_option) do
      'never'       | 'Do not allow'
      'always'      | 'Require'
      'default_on'  | 'Encourage'
      'default_off' | 'Allow'
    end

    with_them do
      let(:described_instance) { described_class.new(squash_option: ProjectSetting.squash_options[squash_option]) }

      subject { described_instance.human_squash_option }

      it { is_expected.to eq(human_squash_option) }
    end
  end

  describe '#branch_rule' do
    let(:described_instance) { described_class.new }

    it 'returns a branch rule' do
      expect(described_instance.branch_rule).to be_kind_of(Projects::BranchRule)
    end
  end
end
