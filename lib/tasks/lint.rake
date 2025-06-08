desc "Run RuboCop for code linting"
task :lint do
  puts "Running RuboCop..."

  # Execute rubocop with github format
  system("bin/rubocop -f github")

  # Exit with the same status code as rubocop
  exit($?.exitstatus)
end
