class CacheUsers
  include CacheLoader

  def self.do_cache
    users = Hash.new
    User.find_each do |user|
      users[user.email] = user
    end

    users
  end
end