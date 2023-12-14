require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

root = File.expand_path("..", __FILE__)

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

set :session_secret, SecureRandom.hex(32)

helpers do
  # def format_text(string)
  #   string.gsub(/\n/, "<br>")
  # end
end

before do
  session[:files] = Dir.glob(root + "/data/*").map{|path| File.basename(path)}
end

get "/" do
  #@files = Dir.glob(root + "/data/*").map{|path| File.basename(path)}
  @files = session[:files]
  erb :index
end

get "/:file" do
  path = root + "/data/" + params[:file]
  #File.read(path) if File.readable?(path)
  if !File.readable?(path)
    session[:error] = "#{params[:file]} does not exist."
    redirect "/"
  else
    headers["Content-Type"] = "text/plain"
    File.read(path)
  end
end