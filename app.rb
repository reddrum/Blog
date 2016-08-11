#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'


def init_db
	@db = SQLite3::Database.new 'Blog.db'
	@db.results_as_hash = true
end

# before вызывается каждый раз при перезагрузке
# либой страницы
before do
	# инициализация БД
	init_db
end

# вызывается каждый раз при конфигурации приложения:
# когда изменился код программы и перезагрузилась страница
configure do
  # инициализация БД
  init_db
	# создает таблицу если таблица не существует
	@db.execute 'CREATE TABLE IF NOT EXISTS Posts
							(
							id INTEGER PRIMARY KEY AUTOINCREMENT,
							created_date DATE,
							content TEXT
							)'

	@db.execute 'CREATE TABLE IF NOT EXISTS Comments
							(
							id INTEGER PRIMARY KEY AUTOINCREMENT,
							created_date DATE,
							content TEXT,
							post_id integer
							)'
end

get '/' do

  # выбираем список постов из БД
  @results = @db.execute 'select * from Posts order by id desc'

  erb :index
end

get '/new' do
  erb :new
end

post '/new' do

  # получаем переменную из post-запроса
  content = params[:content]

  if content.length <= 0
		@error = 'Type post text'
	  return erb :new
  end

  # сохранение данных в БД
  @db.execute 'insert into Posts
							(content, created_date)
							values (?, datetime())', [content]

  redirect to '/'
end

# вывод информации о посте
get '/details/:post_id' do

  # получаем переменную из url
	post_id = params[:post_id]

  # получаем список постов(будет только один пост)
	results = @db.execute 'select * from Posts where id = ?', [post_id]

  # выбираем только один пост в переменную row
  @row = results[0]

  # выбираем комментарии для нашего поста
	@comments = @db.execute 'select * from Comments where post_id = ? order by id', [post_id]
  erb :details
end

post '/details/:post_id' do

	# получаем переменную из url
	post_id = params[:post_id]

  # получаем переменную из post-запроса
	content = params[:content]

	@db.execute 'insert into Comments
							(content, created_date, post_id)
							values (?, datetime(), ?)', [content, post_id]

	redirect to('/details/' + post_id)

end