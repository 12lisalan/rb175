require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

before do
  @contents = File.readlines("data/toc.txt")
end

helpers do
  def in_paragraphs(chapter)
    chapter.split("\n\n").map.with_index do |paragraph, index|
      "<p id='#{index+1}'>#{paragraph}</p>"
    end.join
  end
end
get "/" do
  @title = "The Adventures of Sherlock Holmes"

  erb :home
end

get "/chapters/:number" do
  number = params[:number].to_i
  chapter_name = @contents[number - 1]

  redirect "/" unless (1..@contents.size).cover? number

  @title = "Chapter #{number}: #{chapter_name}"
  @chapter = File.read("data/chp#{number}.txt")

  erb :chapter
end


get "/search" do
  @query = params[:query]
  @result = search_chapter

  erb :search
end

not_found do
  redirect "/"
end

def each_chapter
  @contents.each_with_index do |title, number|
    number = number + 1
    chapter = File.read("data/chp#{number}.txt")
    yield title, number, chapter
  end
end



# returns hash in format {number:title} of chapters containing
# search term
def search_chapter
  result = Hash.new []

  each_chapter do |title, number, chapter|
    paragraphs = chapter.split("\n\n")
    paragraphs.each_with_index do |paragraph, index|
      index = index + 1
      if paragraph.include?(@query)
        paragraph = paragraph.gsub(@query, "<b>#{@query}</b>")
        result[[title, number]] += [[paragraph, index]]
      end
    end
  end

  result
end

