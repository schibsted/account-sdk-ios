class NimbleBeingADickFormatter < XCPretty::Simple
  def format_ld_warning(message); ""; end
  # def format_warning(message); ""; end
  def format_compile_warning(file_name, file_path, reason, line, cursor); ""; end
end

NimbleBeingADickFormatter
