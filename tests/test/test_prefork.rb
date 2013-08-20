
ROOT_PATH = File.expand_path('../..', __FILE__)

if $0 == __FILE__ then
  # require all test cases if not running via rake
  $: << File.expand_path(File.dirname(__FILE__))
  Dir.glob(File.expand_path(File.dirname(__FILE__)) + "/**/*.rb").each do |f|
    next if f =~ /test\/performance/ or f == File.expand_path(__FILE__)
    require f
  end
end

MiniTest::Unit.autorun
