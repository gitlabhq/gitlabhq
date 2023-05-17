# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::WorkItems, feature_category: :team_planning do
  describe '#export_work_items_csv_email' do
    let(:user) { build_stubbed(:user) }
    let(:empty_project) { build_stubbed(:project, path: 'myproject') }
    let(:export_status) { { truncated: false, rows_expected: 3, rows_written: 3 } }
    let(:attachment) { subject.attachments.first }

    subject { Notify.export_work_items_csv_email(user, empty_project, "dummy content", export_status) }

    it_behaves_like 'export csv email', 'work_items'
  end
end
