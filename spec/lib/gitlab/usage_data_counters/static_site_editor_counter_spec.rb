# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::StaticSiteEditorCounter do
  it_behaves_like 'a redis usage counter', 'StaticSiteEditor', :views

  it_behaves_like 'a redis usage counter with totals', :static_site_editor,
    views: 3
end
