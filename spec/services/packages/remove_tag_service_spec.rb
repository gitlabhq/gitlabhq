# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::RemoveTagService, feature_category: :package_registry do
  let!(:package_tag) { create(:packages_tag) }

  describe '#execute' do
    subject { described_class.new(package_tag).execute }

    context 'with existing tag' do
      it { expect { subject }.to change { Packages::Tag.count }.by(-1) }
    end

    context 'with nil' do
      subject { described_class.new(nil) }

      it { expect { subject }.to raise_error(ArgumentError) }
    end
  end
end
