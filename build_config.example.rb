MRuby::Build.new do |conf|
  if ENV["VisualStudioVersion"] || ENV["VSINSTALLDIR"]
    toolchain :visualcpp
  elsif /darwin/ =~ RUBY_PLATFORM
    toolchain :clang
  else
    toolchain :gcc
  end
  conf.bins = []

  # enable debug (remove to disable debug flags)
  enable_debug
  conf.cc.defines = %w(ENABLE_DEBUG)

  # Include all of mruby's Core GEMs
  conf.gembox "full-core"
  conf.gem "#{root}/mrbgems/mruby-bin-debugger"

  # must include this project as a gem so it can be compiled into a binary
  conf.gem File.expand_path(File.dirname(__FILE__))

  # edit mrbgem.rake to add project dependencies
end
