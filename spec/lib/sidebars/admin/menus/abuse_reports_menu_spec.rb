# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Menus::AbuseReportsMenu, feature_category: :navigation do
  it_behaves_like 'Admin menu',
    link: '/admin/abuse_reports',
    title: _('Abuse reports'),
    icon: 'slight-frown'

  it_behaves_like 'Admin menu without sub menus', active_routes: { controller: :abuse_reports }

  describe '#pill_count' do
    let(:user) { build_stubbed(:user, :admin) }

    let(:context) { Sidebars::Context.new(current_user: user, container: nil) }

    subject { described_class.new(context) }

    it 'returns zero when there are no abuse reports' do
      expect(subject.pill_count).to eq 0
    end

    it 'memoizes the query' do
      subject.pill_count

      control = ActiveRecord::QueryRecorder.new do
        subject.pill_count
      end

      expect(control.count).to eq 0
    end

    context 'when there are abuse reports' do
      it 'returns the number of abuse reports' do
        create_list(:abuse_report, 2)

        expect(subject.pill_count).to eq 2
      end
    end
  end
end
