require 'spec_helper'

describe AuditEventPresenter do
  let(:details) do
    {
      author_name: 'author',
      ip_address: '127.0.0.1',
      target_details: 'target name',
      entity_path: 'path',
      from: 'a',
      to: 'b'
    }
  end

  let(:audit_event) { create(:audit_event, details: details) }

  subject(:presenter) do
    described_class.new(audit_event)
  end

  it 'exposes the author name' do
    expect(presenter.author_name).to eq(details[:author_name])
  end

  it 'exposes the target' do
    expect(presenter.target).to eq(details[:target_details])
  end

  it 'exposes the ip address' do
    expect(presenter.ip_address).to eq(details[:ip_address])
  end

  it 'exposes the object' do
    expect(presenter.object).to eq(details[:entity_path])
  end

  it 'exposes the date' do
    expect(presenter.date).to eq(audit_event.created_at.to_s(:db))
  end

  it 'exposes the action' do
    expect(presenter.action).to eq('Changed author from a to b')
  end
end
