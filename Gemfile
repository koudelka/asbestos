source 'https://rubygems.org'

# Specify your gem's dependencies in asbestos.gemspec
gemspec

group :development, :test do
  unless ENV["CI"]
    gem "guard-rspec"
  end
end
