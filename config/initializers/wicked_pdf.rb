WickedPdf.configure do |config|
  config.exe_path = ENV.fetch('WKHTMLTOPDF_PATH') { Gem.bin_path('wkhtmltopdf-binary', 'wkhtmltopdf') }
end
