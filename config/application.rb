require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Eager load all value objects, as they may be instantiated from
# YAML before the symbol is referenced
config.before_initialize do |app|
    app.config.paths.add 'app/values', :eager_load => true
end

# Reload cached/serialized classes before every request (in development
# mode) or on startup (in production mode)
config.to_prepare do
    Dir[ File.expand_path(Rails.root.join("app/values/*.rb")) ].each do |file|
        require_dependency file
    end
    require_dependency 'article_cache'
end

module RailsCacheBugNew
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
