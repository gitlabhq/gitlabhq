require 'spec_helper'

describe Email do
  describe 'validations' do
    it_behaves_like 'an object with email-formated attributes', :email do
      subject { build(:email) }
    end
  end

  it 'normalize email value' do
    expect(described_class.new(email: ' inFO@exAMPLe.com ').email)
      .to eq 'info@example.com'
  end
end
