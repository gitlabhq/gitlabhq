require 'spec_helper'

describe ReferenceChange do
  it { is_expected.to belong_to(:project) }

  it { is_expected.to have_db_column(:newrev).of_type(:string) }
  it { is_expected.to have_db_column(:processed).of_type(:boolean).with_options(default: false, null: false) }

  describe "scopes" do
    describe ".processed" do
      it 'excludes reference changes by default' do
        create(:reference_change)

        expect(described_class.processed.count).to eq 0
      end

      it 'includes processed reference changes' do
        create(:reference_change, processed: true)

        expect(described_class.processed.count).to eq 1
      end
    end
  end
end
