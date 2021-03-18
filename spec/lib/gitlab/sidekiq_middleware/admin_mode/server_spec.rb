# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::AdminMode::Server, :request_store do
  include AdminModeHelper

  let(:worker) do
    Class.new do
      def perform; end
    end
  end

  let(:job) { {} }
  let(:queue) { :test }

  it 'yields block' do
    expect do |b|
      subject.call(worker, job, queue, &b)
    end.to yield_control.once
  end

  context 'job has no admin mode field' do
    it 'session is not bypassed' do
      subject.call(worker, job, queue) do
        expect(Gitlab::Auth::CurrentUserMode.bypass_session_admin_id).to be_nil
      end
    end
  end

  context 'job has admin mode field' do
    let(:admin) { create(:admin) }

    context 'nil admin mode id' do
      let(:job) { { 'admin_mode_user_id' => nil } }

      it 'session is not bypassed' do
        subject.call(worker, job, queue) do
          expect(Gitlab::Auth::CurrentUserMode.bypass_session_admin_id).to be_nil
        end
      end
    end

    context 'valid admin mode id' do
      let(:job) { { 'admin_mode_user_id' => admin.id } }

      it 'session is bypassed' do
        subject.call(worker, job, queue) do
          expect(Gitlab::Auth::CurrentUserMode.bypass_session_admin_id).to be(admin.id)
        end
      end
    end
  end

  context 'admin mode setting disabled' do
    before do
      stub_application_setting(admin_mode: false)
    end

    it 'yields block' do
      expect do |b|
        subject.call(worker, job, queue, &b)
      end.to yield_control.once
    end

    it 'session is not bypassed' do
      subject.call(worker, job, queue) do
        expect(Gitlab::Auth::CurrentUserMode.bypass_session_admin_id).to be_nil
      end
    end
  end
end
