# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Applications::Cilium do
  let(:cilium) { create(:clusters_applications_cilium) }

  include_examples 'cluster application core specs', :clusters_applications_cilium
  include_examples 'cluster application status specs', :clusters_applications_cilium
  include_examples 'cluster application initial status specs'

  describe '#allowed_to_uninstall?' do
    subject { cilium.allowed_to_uninstall? }

    it { is_expected.to be false }
  end
end
