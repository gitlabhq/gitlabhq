# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::YourWork::Menus::MergeRequestsMenu, feature_category: :navigation do
  let(:user) { create(:user) }
  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  subject { described_class.new(context) }

  include_examples 'menu item shows pill based on count', :assigned_open_merge_requests_count
end
