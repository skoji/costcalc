namespace :user do
  desc "Reset password for existing user by email"
  task :reset_password, [:email, :new_password] => :environment do |t, args|
    email = args[:email]
    new_password = args[:new_password]
    
    if email.blank? || new_password.blank?
      puts "Usage: rails user:reset_password[user@example.com,newpassword]"
      exit 1
    end
    
    user = User.find_by(email: email)
    if user.nil?
      puts "User with email '#{email}' not found."
      exit 1
    end
    
    user.password = new_password
    user.password_confirmation = new_password
    
    if user.save
      puts "Password successfully reset for user: #{user.email}"
    else
      puts "Failed to reset password:"
      user.errors.full_messages.each do |error|
        puts "  - #{error}"
      end
    end
  end
  
  desc "List all users"
  task :list => :environment do
    users = User.all
    puts "Total users: #{users.count}"
    users.each do |user|
      puts "  - ID: #{user.id}, Email: #{user.email}, Created: #{user.created_at}"
    end
  end
end