# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/federa/version"

Gem::Specification.new do |s|
  s.version = Decidim::Federa.version
  s.authors = ["Lorenzo Angelone"]
  s.email = ["l.angelone@kapusons.it"]
  s.licenses = ["MIT"]
  s.homepage = "https://github.com/kapusons/decidim-module-federa"
  s.required_ruby_version = ">= 2.7"

  s.name = "decidim-federa"
  s.summary = "A decidim FedERa module"
  s.description = "FedERa Integration for Decidim."

  s.files = Dir["{app,config,lib}/**/*", "Rakefile", "README.md"]

  s.add_dependency "decidim-core", ">= 0.26.x", "< 0.27.x"
  s.add_dependency "omniauth-saml", "~> 2.0"
  # s.add_dependency 'ruby-saml', '~> 1.14.0'
  s.add_dependency "deface", '1.9.0'
end
