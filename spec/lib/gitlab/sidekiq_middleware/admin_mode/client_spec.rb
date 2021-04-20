# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::AdminMode::Client, :request_store do
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
      subject.call(worker, job, queue, nil, &b)
    end.to yield_control.once
  end

  context 'user is a regular user' do
    it 'no admin mode field in payload' do
      subject.call(worker, job, queue, nil) { nil }

      expect(job).not_to include('admin_mode_user_id')
    end
  end

  context 'user is an administrator' do
    let(:admin) { create(:admin) }

    context 'admin mode disabled' do
      it 'no admin mode field in payload' do
        subject.call(worker, job, queue, nil) { nil }

        expect(job).not_to include('admin_mode_user_id')
      end
    end

    context 'admin mode enabled' do
      before do
        enable_admin_mode!(admin)
      end

      context 'when sidekiq required context not set' do
        it 'no admin mode field in payload' do
          subject.call(worker, job, queue, nil) { nil }

          expect(job).not_to include('admin_mode_user_id')
        end
      end

      context 'when user stored in current request' do
        it 'has admin mode field in payload' do
          Gitlab::Auth::CurrentUserMode.with_current_admin(admin) do
            subject.call(worker, job, queue, nil) { nil }

            expect(job).to include('admin_mode_user_id' => admin.id)
          end
        end
      end

      context 'when bypassing session' do
        it 'has admin mode field in payload' do
          Gitlab::Auth::CurrentUserMode.bypass_session!(admin.id) do
            subject.call(worker, job, queue, nil) { nil }

            expect(job).to include('admin_mode_user_id' => admin.id)
          end
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
        subject.call(worker, job, queue, nil, &b)
      end.to yield_control.once
    end

    it 'no admin mode field in payload' do
      subject.call(worker, job, queue, nil) { nil }

      expect(job).not_to include('admin_mode_user_id')
    end
  end
end
