# frozen_string_literal: true

require 'spec_helper'

describe SnippetStatistics do
  it { is_expected.to belong_to(:snippet) }
  it { is_expected.to validate_presence_of(:snippet) }
end
