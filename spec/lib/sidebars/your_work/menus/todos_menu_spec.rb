# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::YourWork::Menus::TodosMenu, feature_category: :navigation do
  let(:user) { build_stubbed(:user) }
  let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

  subject { described_class.new(context) }

  include_examples 'menu item shows pill based on count', :todos_pending_count
end
