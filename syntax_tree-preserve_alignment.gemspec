# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "syntax_tree-preserve_alignment"
  spec.version = "0.3.0"
  spec.summary = "Preserve existing alignment of Ruby assignments and block declarations"
  spec.authors = ["Jean-Denis Koeck"]
  spec.files = Dir["lib/**/*.rb", "README.md"]
  spec.required_ruby_version = ">= 2.7"
  spec.add_dependency "syntax_tree", "= 6.3.0"
  spec.add_development_dependency "rspec", "~> 3.13"
end
