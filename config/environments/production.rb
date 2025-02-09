require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  Rails.application.routes.default_url_options = { host: ENV['HOST_NAME'] }

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.public_file_server.headers = {
    'Cache-Control' => 'public, s-maxage=31536000, max-age=15552000',
    'Pragma' => 'no-cache',
    'X-Content-Type-Options' => 'nosniff'
  }

  # Recommendation of https://www.zaproxy.org/docs/alerts/10015/
  config.action_dispatch.default_headers = {
    'Cache-Control' => 'no-cache, no-store, must-revalidate',
    'Expires' => '0',
    'Pragma' => 'no-cache',
    'X-Content-Type-Options' => 'nosniff',
    'X-Download-Options' => "noopen",
    'X-Frame-Options' => 'deny',
    'X-Permitted-Cross-Domain-Policies' => 'none',
    'Strict-Transport-Security' => 'max-age=31536000; includeSubDomains; preload',
    'X-XSS-Protection' => '1; mode=block',
    'Referrer-Policy' => "strict-origin-when-cross-origin"
  }

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :terser
  # Compress CSS using a preprocessor.
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Include generic and useful information about system operation, but avoid logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII).
  config.log_level = :info

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "place_des_entreprises_production"

  config.action_mailer.asset_host = ENV['HOST_NAME']
  # Actually send emails, but use sendinblue in production and Mailtrap in staging
  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  if ENV['SENDINBLUE_API_KEY'].present?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      user_name: ENV['SENDINBLUE_USER_NAME'],
      password: ENV['SENDINBLUE_SMTP_KEY'],
      address: 'smtp-relay.sendinblue.com',
      port: '587',
      authentication: 'cram_md5'
    }
  elsif ENV['MAILTRAP_USER_NAME'].present? && ENV['FEATURE_SEND_STAGING_EMAILS'].to_b
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      user_name: ENV['MAILTRAP_USER_NAME'],
      password: ENV['MAILTRAP_PASSWORD'],
      address: 'smtp.mailtrap.io',
      domain: 'smtp.mailtrap.io',
      port: '2525',
      authentication: :cram_md5
    }
  else
    config.action_mailer.perform_deliveries = false
  end

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  # config.active_support.report_deprecations = true

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require "syslog/logger"
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new "app-name")

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  if ENV['STAGING_ENV'].present? && ENV['STAGING_ENV'] == 'true'
    # Let Faker load its :en text
    config.i18n.enforce_available_locales = false
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  config.active_storage.service = :ovh
end
