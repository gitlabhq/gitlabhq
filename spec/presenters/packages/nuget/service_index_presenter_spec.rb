# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Nuget::ServiceIndexPresenter do
  let_it_be(:project) { create(:project) }
  let_it_be(:presenter) { described_class.new(project) }

  describe '#version' do
    subject { presenter.version }

    it { is_expected.to eq '3.0.0' }
  end

  describe '#resources' do
    subject { presenter.resources }

    it 'has valid resources' do
      expect(subject.size).to eq 8
      subject.each do |resource|
        %i[@id @type comment].each do |field|
          expect(resource).to have_key(field)
          expect(resource[field]).to be_a(String)
        end
      end
    end
  end
end
