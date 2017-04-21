# based on https://dashboard.diawi.com/docs/apis/upload

module Fastlane
  module Actions

    module SharedValues
      UPLOADED_FILE_LINK_TO_DIAWI = :UPLOADED_FILE_LINK_TO_DIAWI
    end

    class DiawiAction < Action

      ENDPOINT = "https://upload.diawi.com/"

      #####################################################
      # @!group Connection
      #####################################################

      def self.status_connection(token, job)
        require 'faraday'
        require 'faraday_middleware'

        connection = Faraday.new(:url => ENDPOINT) do |builder|
          builder.request :url_encoded
          builder.response :json, content_type: /\bjson$/
          builder.use FaradayMiddleware::FollowRedirects
          builder.adapter :net_http
        end
        connection.get "/status", { :token => token, :job => job }
      end

      def self.upload_connection
        require 'faraday'
        require 'faraday_middleware'

        Faraday.new(url: ENDPOINT) do |builder|
          builder.request :multipart
          builder.request :url_encoded
          builder.request :retry
          builder.response :json, content_type: /\bjson$/
          builder.use FaradayMiddleware::FollowRedirects
          builder.adapter :net_http
        end
      end

      #####################################################
      # @!group Data logic
      #####################################################

      def self.check_status_for_upload(file, token, job)
        # from diawi's documendation:
        # Polling frequence
        # Usually, processing of an upload will take from 0.5 to 5 seconds, so the best polling frequence would be every 1 second for up to 10 times.
        # If the status is still 2001 after 10 seconds, there probably is a problem, let us know.
        availableRequestCount = 5 # 2 sec * 5 times = 10 sec for status check request else raise an error
        requestCount = 0

        status_ok = 2000
        status_in_progress = 2001
        status_error = 4000

        while availableRequestCount > requestCount  do
          response = self.status_connection(token, job)

          case response.body["status"]
          when status_ok
            link = "https://i.diawi.com/#{response.body['hash']}"
            UI.success("File successfully uploaded to diawi. Link: #{link}")
            Actions.lane_context[SharedValues::UPLOADED_FILE_LINK_TO_DIAWI] = link
            return
          when status_in_progress
            UI.message("Uploading...")
          when status_error
            UI.warning("Error uploading file to diawi. Message: #{response.body['message']}")
            UI.warning("Try to upload file by yourself: #{file}")
            return
          else
            UI.warning("Unknown error uploading file to diawi.")
            UI.warning("Try to upload file by yourself: #{file}")
            return
          end

          requestCount += 1
          sleep(2)
        end

        UI.warning("`In progress` status took more than 10 sec, so raise error. Check out the https://dashboard.diawi.com/. Maybe your file has been uploaded successfully.")
        UI.warning("If not, try to upload file by yourself: #{file}")
      end

      def self.upload(file, token, options)
        connection = self.upload_connection

        options.update({
          token: token,
          file: Faraday::UploadIO.new(file, "application/octet-stream")
        })

        post_request = connection.post do |request|
          request.body = options
        end

        post_request.on_complete do |response|
          if response.body && response.body.key?("job")
            return response.body["job"]
          else
            UI.warning("Error uploading file to diawi: #{response.body['message']}")
            return
          end
        end
      end

      #####################################################
      # @!group Run
      #####################################################

      def self.run(options)
        token = options[:token]
        file = options[:file]

        upload_options = options.values.select do |key, value|
          [:password, :comment, :callback_url, :callback_emails].include? key unless value.nil?
        end

        options.values.each do |key, value|
          if [:find_by_udid, :wall_of_apps, :installation_notifications].include? key
            upload_options[key] = value ? 1 : 0 unless value.nil?
          end
        end

        UI.success("Starting with app upload to diawi... this could take some time")

        job = self.upload(file, token, upload_options)

        if job
          self.check_status_for_upload(file, token, job)
        end
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
                               description: "Path to .ipa or .apk file",
                                  optional: false,
                              verify_block: proc do |value|
                                UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                              end),
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
                                  optional: true)
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
