require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "yaml"

before do
  @info = YAML.load_file('users.yaml')
end

helpers do
  def count_interests
    count = 0
    @info.each do |user, info|
      count += info[:interests].size
    end
    count
  end

  def count_users
    @info.keys.size
  end
end

get "/" do
  erb :home
end

get "/:user" do
  @user = params[:user].to_sym

  redirect "/" if !@info[@user]

  @email = @info[@user][:email]
  @interests = @info[@user][:interests]

  erb :user
end



