require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"
require "redcarpet"

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

def logged_in?
  session[:login_status]
end

before do
  #redirect "/users/signin" if !logged_in? && request.path_info != "/users/signin"
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

get "/" do
  pattern = File.join(data_path, '*')
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
  erb :index
end

get "/new" do
  erb :new_file
end

def error_for_file_name(name)
  if name.size == 0
    "A name is required."
  end
end

post "/new" do
  # redirect to form if file name is blank
  # redirect to index after creation
  file_name = params[:file_name]
  error = error_for_file_name(file_name)
  if error
    session[:error] = error
    status 422
    erb :new_file
  else
    File.open(File.join(data_path, file_name), 'w')
    session[:success] = "#{file_name} was created."
    redirect "/"
  end
end

def check_credentials(username, password)
  credentials = {"admin" => "password"}
  credentials[username] == password
end

get "/signin" do
  if check_credentials(params[:username], params[:password])
    session[:login_status] = true
    session[:username] = params[:username]
    session[:success] = "Welcome!"
    redirect "/"
  else
    session[:error] = "Invalid credentials"
    status 422
    erb :login
  end
end

get "/signout" do
  session[:login_status] = false
  session.delete(:username)
  session[:success] = "You have been signed out."
  redirect "/"
end

get "/users/signin" do
  erb :login
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  when ".md"
    erb render_markdown(content)
  else
    content
  end
end

get "/:file" do
  #path = root + "/data/" + params[:file]
  #File.read(path) if File.readable?(path)
  path = File.join(data_path, params[:file])

  if !File.exist?(path)
    session[:error] = "#{params[:file]} does not exist."
    redirect "/"
  else
    load_file_content(path)
  end
end

# renders edit page
get "/:file/edit" do
  #path = root + "/data/" + params[:file]
  path = File.join(data_path, params[:file])
  if !File.file?(path)
    session[:error] = "#{params[:file]} does not exist."
    redirect "/"
  else
    @content = File.read(path)
    erb :edit
  end
end

# edits content of file
post "/:file" do
  #path = root + "/data/" + params[:file]
  path = File.join(data_path, params[:file])
  File.write(path, params[:content])
  session[:success] = "#{params[:file]} has been updated."
  redirect "/"
end

# removes file from system
post "/:file/delete" do
  path = File.join(data_path, params[:file])
  if !File.file?(path)
    session[:error] = "#{params[:file]} does not exist."
  else
    File.delete(path)
    session[:success] = "#{params[:file]} has been deleted."
  end
  redirect "/"
end




