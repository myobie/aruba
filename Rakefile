def invoke(name)
  Rake::Task[name].invoke
end

task :default => :mruby do
  exec "bin/mruby mrblib/main.rb"
end

task :compile => :clean do
  ENV["BUILD_BINARIES"] = "true"
  invoke :mruby
end

def mrbgem_rake(name)
<<-EOF
MRuby::Gem::Specification.new("#{name}") do |spec|
  spec.license = "MIT"
  spec.author  = "Me"
  spec.summary = "Something"
  spec.bins = %w(#{name})
end
EOF
end

task :fork => :build_config do
  name = ENV.fetch("name") { File.basename(__dir__) }
  system "rm -rf .git"
  gitignore = File.read(".gitignore")
  File.open(".gitignore", "w") do |f|
    gitignore.lines.reject { |line| line =~ /build_config\.rb/ }.each do |line|
      f.puts line
    end
  end
  File.open("mrbgem.rake", "w") do |f|
    f.puts mrbgem_rake(name)
  end
  system "mv tools/hello/hello.c tools/hello/#{name}.c"
  system "mv tools/hello tools/#{name}"
  system "rm -rf mruby"
  system "rm README.markdown"
  system "git init"
  system "git submodule add https://github.com/mruby/mruby.git mruby"
  system "git add ."
  system "git commit -am 'Initial commit'"
end

file "build_config.rb" => "build_config.example.rb" do |t|
  cp "build_config.example.rb", "build_config.rb"
end
task :build_config => "build_config.rb"

task :clean do
  Dir.chdir "./mruby" do
    ENV["MRUBY_CONFIG"] = "../build_config.rb"
    system "./minirake clean"
  end
end

file "mruby/build/host/bin/mruby" => "build_config.rb" do
  invoke :clean
  Dir.chdir "./mruby" do
    ENV["MRUBY_CONFIG"] = "../build_config.rb"
    system "./minirake"
  end
  system "cp mruby/build/host/bin/* ./bin/"
end

task :mruby => "mruby/build/host/bin/mruby"
