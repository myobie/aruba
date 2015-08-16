MRuby::Gem::Specification.new("aruba") do |spec|
  spec.license = "MIT"
  spec.author  = "Me"
  spec.summary = "Something"
  spec.bins    = %w(aruba)

  spec.add_dependency 'mruby-uv',          mgem: 'mruby-uv'
  spec.add_dependency 'mruby-http',        mgem: 'mruby-http'
  spec.add_dependency 'mruby-json',        mgem: 'mruby-json'
  spec.add_dependency 'mruby-catch-throw', mgem: 'mruby-catch-throw'
  spec.add_dependency 'mruby-onig-regexp', mgem: 'mruby-onig-regexp'
end
