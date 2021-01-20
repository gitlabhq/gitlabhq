# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'notify/pipeline_success_email.text.erb' do
  it_behaves_like 'pipeline status changes email' do
    let(:title) { "Pipeline ##{pipeline.id} has passed!" }
    let(:status) { :success }
  end
end
