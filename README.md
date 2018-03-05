# diawi plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-diawi)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-diawi`, add it to your project by running:

```bash
fastlane add_plugin diawi
```

## About diawi

Diawi is a tool for developers to deploy Development and In-house applications directly to the devices.
This plugin can upload .ipa and .apk file to diawi.

## Available options

Key | Required | Type | Description
--- | --- | --- | ---
**token** | **`true`** | `String` | [API access token](https://dashboard.diawi.com/profile/api)
**file** | **`true`** | `String` | Path to .ipa or .apk file
**find_by_udid** | `false` | `Boolean` | Allow your testers to find the app on diawi's mobile web app using their UDID (**iOS only**)
**wall_of_apps** | `false` | `Boolean` | Allow diawi to display the app's icon on the wall of apps
**password** | `false` | `String` | Protect your app with a password: it will be required to access the installation page
**comment** | `false` | `String` | Additional information to your users on this build: the comment will be displayed on the installation page
**callback_url** | `false` | `String` | The URL diawi should call with the result
**callback_emails** | `false` | `String` | The email addresses diawi will send the result to (up to 5 separated by commas for starter/premium/enterprise accounts, 1 for free accounts). Emails should be a string. Ex: "example@test.com,example1@test.com"
**installation_notifications** | `false` | `Boolean` | Receive notifications each time someone installs the app (only starter/premium/enterprise accounts)
**last_hope_attempts_count**⁺ | `false` | `Int` | Number of extra attempts to check file status (default: 1, max: 5, not in range (1...5): 1)

<details><summary>⁺ Explanation</summary><p>
    
From [diawi's documentation](https://dashboard.diawi.com/docs/apis/upload):

> Polling frequence  
> If possible, prefer using the callbacks than the polling: they will always provide you with the result as soon as it is available.
>
> Usually, processing of an upload will take a few seconds: so, a base rule would be to poll every 2 seconds for up to 5 times and should match most simple use-cases.
>
> For larger apps, a longer processing might be needed on our side. A rule of thumb would be to wait up to 1 second for each 10 MB of the app. In other words, up to 10 seconds for a 100 MB app, 50 seconds for a 500 MB app, and so on…
>
> If the status is still 2001 after that duration, there probably is a problem, let us know.

Technically your app can be uploaded to diawi, but still processing for a while. In this case `last_hope_attempts_count` can add extra `n` check status requests.

Example:  
```ruby
last_hope_attempts_count = 3  
app_size = 23 MB  
check_attempts = 23 / 10 + last_hope_attempts_count = 5 # total attempts is 5; but it will return at first success response
```
    
</p></details>

## Result link

If file upload successfully, you can access result link by:  

`lane_context[SharedValues::UPLOADED_FILE_LINK_TO_DIAWI]`

## Example

Minimal plugin configuration is:  
```ruby
diawi(
    token: "your_api_token",
    file: "path_to_ipa_or_apk_file"
)
```

For more options see [**Available options**](#available-options) section.

## Issues and Feedback

For any other issues and feedback about this plugin, please submit it to this repository.

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
