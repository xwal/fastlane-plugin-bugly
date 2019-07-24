require 'fastlane/action'
require_relative '../helper/bugly_helper'
require 'faraday'
require 'faraday_middleware'

module Fastlane
  module Actions
    class BuglyAction < Action
      def self.run(params)
        UI.message("The bugly plugin is working!")
        api_host = "https://api.bugly.qq.com/openapi/file/upload/symbol"
        app_id = params[:app_id]
        app_key = params[:app_key]
        symbol_type = params[:symbol_type]
        bundle_id = params[:bundle_id]
        product_version = params[:product_version]
        channel = params[:channel]

        file_path = params[:dsym]
        file_path ||= Actions.lane_context[SharedValues::DSYM_OUTPUT_PATH] || ENV[SharedValues::DSYM_OUTPUT_PATH.to_s]
        file_path ||= Actions.lane_context[SharedValues::DSYM_ZIP_PATH] || ENV[SharedValues::DSYM_ZIP_PATH.to_s]

        if file_path.nil?
          UI.user_error!("You have to provide a dsym file")
        end

        UI.message("dsym file: #{file_path}")

        # start upload
        conn_options = {
          request: {
            timeout:       1000,
            open_timeout:  300
          }
        }

        bugly_client = Faraday.new(nil, conn_options) do |c|
          c.request :multipart
          c.request :url_encoded
          c.response :json, content_type: /\bjson$/
          c.adapter :net_http
        end

        params = {
          'api_version' => 1,
          'app_id' => app_id,
          'app_key' => app_key,
          'symbolType' => symbol_type,
          'bundleId' => bundle_id,
          'productVersion' => product_version,
          'channel' => channel,
          'fileName' => File.basename(file_path),
          'file' => Faraday::UploadIO.new(file_path, 'application/octet-stream')
        }

        UI.message "Start upload #{file_path} to bugly..."

        response = bugly_client.post api_host do |req|
          req.params[:app_id] = app_id
          req.params[:app_key] = app_key
          req.body = params
        end

        UI.success "Upload success."
      end

      def self.description
        "Upload dSYM to bugly."
      end

      def self.authors
        ["pilihuo"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "Upload dSYM to bugly."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :app_id,
                                  env_name: "BUGLY_APP_ID",
                               description: "App ID in your bugly app setting",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :app_key,
                                  env_name: "BUGLY_APP_KEY",
                               description: "App Key in your bugly app setting",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :symbol_type,
                                  env_name: "BUGLY_SYMBOL_TYPE",
                               description: "symbol type for project: Mapping: 1, iOS: 2, Symbol: 3",
                                  optional: false,
                                      type: Integer),                            
          FastlaneCore::ConfigItem.new(key: :bundle_id,
                                  env_name: "BUGLY_BUNDLE_ID",
                               description: "bundle identifier for project",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :product_version,
                                  env_name: "BUGLY_PRODUCT_VERSION",
                               description: "set product version for dSYM",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :channel,
                                  env_name: "BUGLY_CHANNEL",
                               description: "set channel for dSYM",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :dsym,
                                  env_name: "BUGLY_DSYM_FILE",
                               description: "dSYM.zip file to upload",
                                  optional: true,
                                      type: String)
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        [:ios, :mac, :android].include?(platform)
        true
      end
    end
  end
end
