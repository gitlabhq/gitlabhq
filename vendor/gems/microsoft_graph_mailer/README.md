# microsoft_graph_mailer

This gem allows delivery of emails using [Microsoft Graph API](https://learn.microsoft.com/en-us/graph/api/user-sendmail) with [OAuth 2.0 client credentials flow](https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-client-creds-grant-flow).

## The reason for this gem

See [https://gitlab.com/groups/gitlab-org/-/epics/8259](https://gitlab.com/groups/gitlab-org/-/epics/8259).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'microsoft_graph_mailer'
```

And then execute:

```shell
bundle
```

Or install it yourself as:

```shell
gem install microsoft_graph_mailer
```

## Settings

To use the Microsoft Graph API to send mails, you will
need to create an application in the Azure Active Directory. See the
[Microsoft instructions](https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app) for more details:

1. Sign in to the [Azure portal](https://portal.azure.com).
1. Search for and select `Azure Active Directory`.
1. Under `Manage`, select `App registrations` > `New registration`.
1. Enter a `Name` for your application, such as `MicrosoftGraphMailer`. Users of your app might see this name, and you can change it later.
1. If `Supported account types` is listed, select the appropriate option.
1. Leave `Redirect URI` blank. This is not needed.
1. Select `Register`.
1. Under `Manage`, select `Certificates & secrets`.
1. Under `Client secrets`, select `New client secret`, and enter a name.
1. Under `Expires`, select `Never`, unless you plan on updating the credentials every time it expires.
1. Select `Add`. Record the secret value in a safe location for use in a later step.
1. Under `Manage`, select `API Permissions` > `Add a permission`. Select `Microsoft Graph`.
1. Select `Application permissions`.
1. Under the `Mail` node, select `Mail.Send`. Then select Add permissions.
1. If `User.Read` is listed in the permission list, you can delete this.
1. Click `Grant admin consent` for these permissions.

- `user_id` - The unique identifier for the user. To use Microsoft Graph on behalf of the user.
- `tenant` - The directory tenant the application plans to operate against, in GUID or domain-name format.
- `client_id` - The application ID that's assigned to your app. You can find this information in the portal where you registered your app.
- `client_secret` - The client secret that you generated for your app in the app registration portal.

## Usage

```ruby
require "microsoft_graph_mailer"

microsoft_graph_mailer = MicrosoftGraphMailer::Delivery.new(
  {
    user_id: "YOUR-USER-ID",
    tenant: "YOUR-TENANT-ID",
    client_id: "YOUR-CLIENT-ID",
    client_secret: "YOUR-CLIENT-SECRET-ID"
    # Defaults to "https://login.microsoftonline.com".
    azure_ad_endpoint: "https://login.microsoftonline.us",
    # Defaults to "https://graph.microsoft.com".
    graph_endpoint: "https://graph.microsoft.us"
  }
)

message = Mail.new do
  from "about@gitlab.com"
  to "to@example.com"
  subject "GitLab Mission"

  html_part do
    content_type "text/html; charset=UTF-8"
    body "It is GitLab's mission to make it so that <strong>everyone can contribute</strong>."
  end
end

microsoft_graph_mailer.deliver!(message)
```

## Usage with ActionMailer

```ruby
ActionMailer::Base.delivery_method = :microsoft_graph

ActionMailer::Base.microsoft_graph_settings = {
  user_id: "YOUR-USER-ID",
  tenant: "YOUR-TENANT-ID",
  client_id: "YOUR-CLIENT-ID",
  client_secret: "YOUR-CLIENT-SECRET-ID"
  # Defaults to "https://login.microsoftonline.com".
  azure_ad_endpoint: "https://login.microsoftonline.us",
  # Defaults to "https://graph.microsoft.com".
  graph_endpoint: "https://graph.microsoft.us"
}
```
