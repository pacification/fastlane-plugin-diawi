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

## Migration to 2.0.0

`last_hope_attempts_count` - removed.

`last_hope_attempts_backoff` - renamed to `check_status_delay`.

`timeout` - new key.

For more info see [2.0.0 pull request](https://github.com/pacification/fastlane-plugin-diawi/pull/16).

## Available options

Key | Required | Type | Description
--- | --- | --- | ---
**token** | **`true`** | `String` | [API access token](https://dashboard.diawi.com/profile/api)
**file** | `false` | `String` | Path to .ipa or .apk file.<br>**Default**: `IPA_OUTPUT_PATH` or `GRADLE_APK_OUTPUT_PATH` based on platform
**find_by_udid** | `false` | `Boolean` | Allow your testers to find the app on diawi's mobile web app using their UDID (**iOS only**)
**wall_of_apps** | `false` | `Boolean` | Allow diawi to display the app's icon on the wall of apps
**password** | `false` | `String` | Protect your app with a password: it will be required to access the installation page
**comment** | `false` | `String` | Additional information to your users on this build: the comment will be displayed on the installation page
**callback_url** | `false` | `String` | The URL diawi should call with the result
**callback_emails** | `false` | `String` | The email addresses diawi will send the result to (up to 5 separated by commas for starter/premium/enterprise accounts, 1 for free accounts). Emails should be a string. Ex: "example@test.com,example1@test.com"
**installation_notifications** | `false` | `Boolean` | Receive notifications each time someone installs the app (only starter/premium/enterprise accounts)
**timeout** | `false` | `Int` | Timeout for checking upload status in seconds.<br>**Default**: 60<br>**Range**: (5, 1800)
**check_status_delay** | `false` | `Int` | Number of seconds to wait between repeated attempts at checking upload status.<br>**Default**: 3<br>**Range**: (1, 30)

## Result link

If file upload successfully, you can access result link by:  

`lane_context[SharedValues::UPLOADED_FILE_LINK_TO_DIAWI]`

## Example

Minimal plugin configuration is:  
```ruby
diawi(
    token: "your_api_token"
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
