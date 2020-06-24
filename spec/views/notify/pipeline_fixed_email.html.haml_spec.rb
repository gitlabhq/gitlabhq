# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'notify/pipeline_fixed_email.html.haml' do
  it_behaves_like 'pipeline status changes email' do
    let(:title) { 'Your pipeline has been fixed!' }
    let(:status) { :success }
  end
end
