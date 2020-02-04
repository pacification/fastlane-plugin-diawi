# based on https://dashboard.diawi.com/docs/apis/upload

module Fastlane
    module Actions

        module SharedValues
            UPLOADED_FILE_LINK_TO_DIAWI = :UPLOADED_FILE_LINK_TO_DIAWI
        end

        class DiawiAction < Action

            UPLOAD_URL = "https://upload.diawi.com/"
            STATUS_CHECK_URL = "https://upload.diawi.com/status"
            DIAWI_FILE_LINK = "https://i.diawi.com"

            def self.run(options)
                Actions.verify_gem!('rest-client')
                require 'rest-client'
                require 'json'

                if options[:file].nil?
                    UI.important("File didn't come to diawi_plugin. Uploading is unavailable.")
                    return
                end

                if options[:token].nil?
                    UI.important("Diawi token is nil - uploading is unavailable.")
                    UI.important("Try to upload file by yourself. Path: #{options[:file]}")
                    return
                end

                upload_options = options.values.select do |key, value|
                    [:password, :comment, :callback_url, :callback_emails].include? key unless value.nil?
                end

                options.values.each do |key, value|
                    if [:find_by_udid, :wall_of_apps, :installation_notifications].include? key
                        upload_options[key] = value ? 1 : 0 unless value.nil?
                    end
                end

                upload_options[:token] = options[:token]
                upload_options[:file] = File.new(options[:file], 'rb')

                UI.success("Start uploading file to diawi. Please, be patient. This could take some time.")

                response = RestClient.post(UPLOAD_URL, upload_options)

                begin
                    response
                rescue RestClient::ExceptionWithResponse => error
                    UI.important("Faild to upload file to diawi, because of:")
                    UI.important(error)
                    UI.important("Try to upload file by yourself. Path: #{options[:file]}")
                    return
                end

                job = JSON.parse(response.body)['job']
                UI.success("Upload success. Processing started, job=#{job} Please, be patient. This could take some time.")
                
                if job
                    return self.check_status(options[:token], options[:file], job, options[:last_hope_attempts_count], options[:last_hope_attempts_backoff])
                end

                UI.important("Something went wrong and `job` value didn't come from uploading request. Check out your dashboard: https://dashboard.diawi.com/. Maybe your file already has been uploaded successfully.")
                UI.important("If not, try to upload file by yourself. Path: #{options[:file]}")
            end

            def self.check_status(token, file, job, last_hope_attempts_count, last_hope_attempts_backoff)
                # From documendation:

                # Polling frequence
                # Usually, processing of an upload will take a few seconds:
                # so, a base rule would be to poll every 2 seconds for up to 5 times and should match most simple use-cases.

                # For larger apps, a longer processing might be needed on our side.
                # A rule of thumb would be to wait up to 1 second for each 10 MB of the app.
                # In other words, up to 10 seconds for a 100 MB app, 50 seconds for a 500 MB app, and so on…

                # ^ Based on this here we calculate polling_count

                file_size = (File.size(file).to_i) / 2**20
                additional_polling_count = last_hope_attempts_count.between?(1, 5) ? last_hope_attempts_count : 1
                polling_count = file_size / 10 + additional_polling_count # also add "last hope" attempts

                polling_attempts = 0

                status_ok = 2000
                status_in_progress = 2001
                status_error = 4000

                # According to:
                #
                # "processing of an upload will take a few seconds: a base rule would be to poll every 2 seconds".
                #
                # here introduced sleep 2 seconds before first check requst.
                # it should solve the problem with check status of small file size (> 10 mb).
                # if you need more attempts, use `DIAWI_LAST_HOPE_ATTEMPTS_COUNT`.
                sleep(2)

                while polling_count > polling_attempts  do
                    response = RestClient.get STATUS_CHECK_URL, {params: {token: token, job: job}}

                    begin
                        response
                    rescue RestClient::ExceptionWithResponse => error
                        UI.important("Check file status request error:")
                        UI.important(error)
                        polling_attempts += 1
                        sleep(2)
                        next
                    end

                    json = JSON.parse(response.body)

                    case json['status']
                    when status_ok
                        link = "#{DIAWI_FILE_LINK}/#{json['hash']}"
                        UI.success("File successfully uploaded to diawi. Link: #{link}")
                        Actions.lane_context[SharedValues::UPLOADED_FILE_LINK_TO_DIAWI] = link
                        return

                    when status_in_progress
                        UI.message("Processing file...")

                    when status_error
                        UI.important("Error uploading file to diawi.")
                        UI.important(json['message'])
                    else
                        UI.important("Unknown error uploading file to diawi.")
                    end

                    polling_attempts += 1
                    sleep(last_hope_attempts_backoff)
                end

                UI.important("File is not processed.")
                UI.important("Try to upload file by yourself: #{file}")
            end

            def self.default_file_path
                platform = Actions.lane_context[SharedValues::PLATFORM_NAME]
                ios_path = Actions.lane_context[SharedValues::IPA_OUTPUT_PATH]
                android_path = Actions.lane_context[SharedValues::GRADLE_APK_OUTPUT_PATH]
                return platform == :ios ? ios_path : android_path 
            end

            #####################################################
            # @!group Documentation
            #####################################################

            def self.available_options
                [
                    FastlaneCore::ConfigItem.new(key: :token,
                                            env_name: "DIAWI_TOKEN",
                                         description: "API access token",
                                            optional: false),
                    FastlaneCore::ConfigItem.new(key: :file,
                                            env_name: "DIAWI_FILE",
                                         description: "Path to .ipa or .apk file. Default - `IPA_OUTPUT_PATH` or `GRADLE_APK_OUTPUT_PATH` based on platform",
                                            optional: true,
                                       default_value: self.default_file_path),
                    FastlaneCore::ConfigItem.new(key: :find_by_udid,
                                            env_name: "DIAWI_FIND_BY_UDID",
                                         description: "Allow your testers to find the app on diawi's mobile web app using their UDID (iOS only)",
                                           is_string: false,
                                            optional: true),
                    FastlaneCore::ConfigItem.new(key: :wall_of_apps,
                                            env_name: "DIAWI_WALL_OF_APPS",
                                         description: "Allow diawi to display the app's icon on the wall of apps",
                                           is_string: false,
                                            optional: true),
                    FastlaneCore::ConfigItem.new(key: :password,
                                            env_name: "DIAWI_PASSWORD",
                                         description: "Protect your app with a password: it will be required to access the installation page",
                                            optional: true),
                    FastlaneCore::ConfigItem.new(key: :comment,
                                            env_name: "DIAWI_COMMENT",
                                         description: "Additional information to your users on this build: the comment will be displayed on the installation page",
                                            optional: true),
                    FastlaneCore::ConfigItem.new(key: :callback_url,
                                            env_name: "DIAWI_CALLBACK_URL",
                                         description: "The URL diawi should call with the result",
                                            optional: true,
                                        verify_block: proc do |value|
                                          UI.user_error!("The `callback_url` not valid.") if value =~ URI::regexp
                                        end),
                    FastlaneCore::ConfigItem.new(key: :callback_emails,
                                            env_name: "DIAWI_CALLBACK_EMAILS",
                                         description: "The email addresses diawi will send the result to (up to 5 separated by commas for starter/premium/enterprise accounts, 1 for free accounts). Emails should be a string. Ex: \"example@test.com,example1@test.com\"",
                                            optional: true),
                    FastlaneCore::ConfigItem.new(key: :installation_notifications,
                                            env_name: "DIAWI_INSTALLATION_NOTIFICATIONS",
                                         description: "Receive notifications each time someone installs the app (only starter/premium/enterprise accounts)",
                                           is_string: false,
                                            optional: true),
                    FastlaneCore::ConfigItem.new(key: :last_hope_attempts_count,
                                            env_name: "DIAWI_LAST_HOPE_ATTEMPTS_COUNT",
                                         description: "Number of attempts to check status after last attempt. Default - 1, max - 5. (See more at `self.check_status` func comment)",
                                           is_string: false,
                                            optional: true,
                                       default_value: 1),
                    FastlaneCore::ConfigItem.new(key: :last_hope_attempts_backoff,
                                            env_name: "DIAWI_LAST_HOPE_ATTEMPTS_BACKOFF",
                                         description: "Number of seconds to wait between repeated attempts at checking upload status. Default - 2. (See more at `self.check_status` func comment)",
                                           is_string: false,
                                            optional: true,
                                       default_value: 2)
                ]
            end

            def self.output
                [
                    ['UPLOADED_FILE_LINK_TO_DIAWI', 'URL to uploaded .ipa or .apk file to diawi.']
                ]
            end

            def self.description
                "Upload .ipa/.apk file to diawi.com"
            end

            def self.authors
                ["pacification"]
            end

            def self.details
                "This action upload .ipa/.apk file to https://www.diawi.com and return link to uploaded file."
            end

            def self.is_supported?(platform)
                [:ios, :android].include?(platform)
            end

        end

    end
end
