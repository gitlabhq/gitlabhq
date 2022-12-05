# frozen_string_literal: true

RSpec.shared_examples 'updating the dependency proxy image ttl policy attributes' do |to:, from: {}|
  it_behaves_like 'not creating the dependency proxy image ttl policy'

  it 'updates the dependency proxy image ttl policy' do
    expect { subject }
      .to change { group.dependency_proxy_image_ttl_policy.reload.enabled }.from(from[:enabled]).to(to[:enabled])
      .and change { group.dependency_proxy_image_ttl_policy.reload.ttl }.from(from[:ttl]).to(to[:ttl])
  end
end

RSpec.shared_examples 'not creating the dependency proxy image ttl policy' do
  it "doesn't create the dependency proxy image ttl policy" do
    expect { subject }.not_to change { DependencyProxy::ImageTtlGroupPolicy.count }
  end
end

RSpec.shared_examples 'creating the dependency proxy image ttl policy' do
  it 'creates a new package setting' do
    expect { subject }.to change { DependencyProxy::ImageTtlGroupPolicy.count }.by(1)
  end

  it 'saves the settings' do
    subject

    expect(group.dependency_proxy_image_ttl_policy).to have_attributes(
      enabled: ttl_policy[:enabled],
      ttl: ttl_policy[:ttl]
    )
  end

  it_behaves_like 'returning a success'
end
